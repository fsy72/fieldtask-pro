import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/entities/intervention_load_result.dart';
import '../../domain/entities/intervention.dart';
import '../../domain/entities/intervention_change_result.dart';
import '../../domain/entities/photo_upload_result.dart';
import '../../domain/entities/intervention_photo.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../datasources/intervention_local_data_source.dart';
import '../datasources/intervention_remote_data_source.dart';
import '../models/intervention_model.dart';

class InterventionRepositoryImpl implements InterventionRepository {
  const InterventionRepositoryImpl(this._remote, this._local);

  final InterventionRemoteDataSource _remote;
  final InterventionLocalDataSource _local;

  @override
  Future<InterventionLoadResult> getAssigned({
    required int technicianId,
  }) async {
    try {
      final remoteInterventions = await _remote.getAssigned();
      await _local.replaceForTechnician(
        technicianId: technicianId,
        interventions: remoteInterventions,
      );
      return InterventionLoadResult(
        interventions: remoteInterventions,
        isFromCache: false,
        cacheUpdatedAt: DateTime.now(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) rethrow;
      final cache = await _local.readForTechnician(technicianId);
      if (cache.interventions.isEmpty) rethrow;
      return InterventionLoadResult(
        interventions: cache.interventions,
        isFromCache: true,
        cacheUpdatedAt: cache.updatedAt,
      );
    }
  }

  @override
  Future<InterventionChangeResult> updateStatus({
    required int technicianId,
    required Intervention intervention,
    required String status,
  }) async {
    try {
      final pending = await _local.pendingChange(
        technicianId: technicianId,
        interventionId: intervention.id,
      );
      final includeNotes = pending?['includes_notes'] == 1;
      final updated = await _remote.updateIntervention(
        intervention: intervention,
        status: status,
        notes: includeNotes ? pending!['notes'] as String? : null,
        includeNotes: includeNotes,
      );
      await _local.resolvePendingChange(
        technicianId: technicianId,
        intervention: updated,
      );
      return InterventionChangeResult(
        intervention: updated,
        isQueued: false,
      );
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      final localIntervention = intervention is InterventionModel
          ? intervention
          : InterventionModel(
              id: intervention.id,
              clientUuid: intervention.clientUuid,
              client: intervention.client,
              address: intervention.address,
              description: intervention.description,
              equipment: intervention.equipment,
              status: intervention.status,
              priority: intervention.priority,
              latitude: intervention.latitude,
              longitude: intervention.longitude,
              scheduledAt: intervention.scheduledAt,
              notes: intervention.notes,
              syncVersion: intervention.syncVersion,
              updatedAt: intervention.updatedAt,
            );
      final queued = localIntervention.copyWith(status: status);
      await _local.queueStatusUpdate(
        technicianId: technicianId,
        intervention: queued,
        status: status,
      );
      return InterventionChangeResult(
        intervention: queued,
        isQueued: true,
      );
    }
  }

  @override
  Future<InterventionChangeResult> updateNotes({
    required int technicianId,
    required Intervention intervention,
    required String? notes,
  }) async {
    final localIntervention = _asModel(intervention);
    final updatedLocally =
        localIntervention.copyWith(notes: notes, clearNotes: notes == null);
    try {
      final pending = await _local.pendingChange(
        technicianId: technicianId,
        interventionId: intervention.id,
      );
      final updated = await _remote.updateIntervention(
        intervention: intervention,
        status: pending?['status'] as String? ?? intervention.status,
        notes: notes,
        includeNotes: true,
      );
      await _local.resolvePendingChange(
        technicianId: technicianId,
        intervention: updated,
      );
      return InterventionChangeResult(
        intervention: updated,
        isQueued: false,
      );
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      await _local.queueNotesUpdate(
        technicianId: technicianId,
        intervention: updatedLocally,
        notes: notes,
      );
      return InterventionChangeResult(
        intervention: updatedLocally,
        isQueued: true,
      );
    }
  }

  @override
  Future<PhotoUploadResult> uploadPhoto({
    required int technicianId,
    required String interventionId,
    String? filePath,
    Uint8List? bytes,
    String type = 'photo',
    String? caption,
  }) async {
    final clientUuid = _newUuid();
    final savedPath = await _local.queuePhoto(
      technicianId: technicianId,
      interventionId: interventionId,
      clientUuid: clientUuid,
      sourcePath: filePath,
      sourceBytes: bytes,
      type: type,
      caption: caption,
    );
    try {
      await _remote.uploadPhoto(
        interventionId: interventionId,
        clientUuid: clientUuid,
        filePath: savedPath,
        type: type,
        caption: caption,
      );
      await _local.removePendingPhoto(clientUuid);
      return const PhotoUploadResult(isQueued: false);
    } on DioException catch (error) {
      if (_isNetworkFailure(error)) {
        return const PhotoUploadResult(isQueued: true);
      }
      await _local.removePendingPhoto(clientUuid);
      rethrow;
    } catch (_) {
      await _local.removePendingPhoto(clientUuid);
      rethrow;
    }
  }

  @override
  Future<List<InterventionPhoto>> getPhotos({
    required int technicianId,
    required String interventionId,
  }) async {
    final photos = <InterventionPhoto>[];
    try {
      photos.addAll(await _remote.getPhotos(interventionId: interventionId));
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
    }
    final pending = await _local.pendingPhotos(technicianId);
    for (final item in pending.where(
      (photo) => photo['intervention_id'] == interventionId,
    )) {
      final filePath = item['file_path']! as String;
      try {
        final bytes = await File(filePath).readAsBytes();
        photos.add(InterventionPhoto(
          id: item['client_uuid']! as String,
          bytes: bytes,
          type: item['type'] as String? ?? 'photo',
          caption: item['caption'] as String?,
        ));
      } on FileSystemException {
        // A missing queued file will be handled by the sync queue.
      }
    }
    return photos;
  }

  @override
  Future<int> syncPendingChanges({required int technicianId}) async {
    final pending = await _local.pendingChanges(technicianId);
    final cached = await _local.readForTechnician(technicianId);
    final interventions = {
      for (final intervention in cached.interventions) intervention.id: intervention,
    };
    var conflicts = 0;

    for (final update in pending) {
      final id = update['intervention_id']! as String;
      final status = update['status']! as String;
      final includesNotes = update['includes_notes'] == 1;
      final notes = update['notes'] as String?;
      final intervention = interventions[id];
      if (intervention == null) {
        await _local.markChangeConflict(
          technicianId: technicianId,
          interventionId: id,
        );
        conflicts++;
        continue;
      }
      final baseVersion = update['sync_version']! as int;
      try {
        final updated = await _remote.updateIntervention(
          intervention: intervention.copyWith(syncVersion: baseVersion),
          status: status,
          notes: notes,
          includeNotes: includesNotes,
        );
        await _local.resolvePendingChange(
          technicianId: technicianId,
          intervention: updated,
        );
      } on DioException catch (error) {
        if (error.response?.statusCode == 409) {
          final current = _conflictingIntervention(error.response?.data);
          if (current != null &&
              current.status == status &&
              (!includesNotes || current.notes == notes)) {
            await _local.resolvePendingChange(
              technicianId: technicianId,
              intervention: current,
            );
          } else {
            await _local.markChangeConflict(
              technicianId: technicianId,
              interventionId: id,
            );
            conflicts++;
          }
          continue;
        }
        if (_isNetworkFailure(error)) break;
        rethrow;
      }
    }

    final pendingPhotos = await _local.pendingPhotos(technicianId);
    for (final photo in pendingPhotos) {
      final clientUuid = photo['client_uuid']! as String;
      try {
        await _remote.uploadPhoto(
          interventionId: photo['intervention_id']! as String,
          clientUuid: clientUuid,
          filePath: photo['file_path']! as String,
          type: photo['type'] as String? ?? 'photo',
          caption: photo['caption'] as String?,
        );
        await _local.removePendingPhoto(clientUuid);
      } on DioException catch (error) {
        if (_isNetworkFailure(error)) break;
        rethrow;
      }
    }
    return conflicts;
  }

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  InterventionModel? _conflictingIntervention(Object? response) {
    if (response is! Map<String, dynamic>) return null;
    final current = response['current'];
    if (current is! Map<String, dynamic>) return null;
    final data = current['data'] is Map<String, dynamic>
        ? current['data'] as Map<String, dynamic>
        : current;
    return InterventionModel.fromJson(data);
  }

  InterventionModel _asModel(Intervention intervention) =>
      intervention is InterventionModel
          ? intervention
          : InterventionModel(
              id: intervention.id,
              clientUuid: intervention.clientUuid,
              client: intervention.client,
              address: intervention.address,
              description: intervention.description,
              equipment: intervention.equipment,
              status: intervention.status,
              priority: intervention.priority,
              latitude: intervention.latitude,
              longitude: intervention.longitude,
              scheduledAt: intervention.scheduledAt,
              notes: intervention.notes,
              syncVersion: intervention.syncVersion,
              updatedAt: intervention.updatedAt,
            );

  bool _isNetworkFailure(DioException error) => switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => true,
        _ => false,
      };
}
