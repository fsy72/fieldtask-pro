import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/datasources/intervention_local_data_source.dart';
import '../data/datasources/intervention_remote_data_source.dart';
import '../data/repositories/intervention_repository_impl.dart';
import '../domain/entities/intervention.dart';
import '../domain/entities/intervention_load_result.dart';
import '../domain/entities/intervention_change_result.dart';
import '../domain/entities/photo_upload_result.dart';
import '../domain/entities/intervention_photo.dart';
import '../domain/repositories/intervention_repository.dart';
import '../domain/usecases/get_assigned_interventions.dart';
import '../domain/usecases/update_intervention_notes.dart';
import '../domain/usecases/update_intervention_status.dart';
import '../domain/usecases/upload_intervention_photo.dart';

final connectivityStatusProvider =
    StreamProvider<List<ConnectivityResult>>((ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

final interventionRepositoryProvider = Provider<InterventionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return InterventionRepositoryImpl(
    InterventionRemoteDataSource(api.dio, tokenStorage),
    InterventionLocalDataSource(ref.watch(appDatabaseProvider)),
  );
});

final getAssignedInterventionsProvider = Provider<GetAssignedInterventions>(
  (ref) => GetAssignedInterventions(ref.watch(interventionRepositoryProvider)),
);

final updateInterventionStatusProvider = Provider<UpdateInterventionStatus>(
  (ref) => UpdateInterventionStatus(ref.watch(interventionRepositoryProvider)),
);

final updateInterventionNotesProvider = Provider<UpdateInterventionNotes>(
  (ref) => UpdateInterventionNotes(ref.watch(interventionRepositoryProvider)),
);

final uploadInterventionPhotoProvider = Provider<UploadInterventionPhoto>(
  (ref) => UploadInterventionPhoto(ref.watch(interventionRepositoryProvider)),
);

final interventionsControllerProvider =
    AsyncNotifierProvider<InterventionsController, InterventionLoadResult>(
  InterventionsController.new,
);

class InterventionsController extends AsyncNotifier<InterventionLoadResult> {
  late int _technicianId;

  Future<InterventionLoadResult> _load() =>
      ref.read(getAssignedInterventionsProvider).call(
            technicianId: _technicianId,
          );

  @override
  Future<InterventionLoadResult> build() {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) throw StateError('Session technicien introuvable.');
    _technicianId = user.id;
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<InterventionChangeResult> updateStatus({
    required Intervention intervention,
    required String status,
  }) async {
    final result = await ref.read(updateInterventionStatusProvider).call(
          technicianId: _technicianId,
          intervention: intervention,
          status: status,
        );
    _replaceInState(result.intervention, isFromCache: result.isQueued);
    return result;
  }

  Future<InterventionChangeResult> updateNotes({
    required Intervention intervention,
    required String? notes,
  }) async {
    final result = await ref.read(updateInterventionNotesProvider).call(
          technicianId: _technicianId,
          intervention: intervention,
          notes: notes,
        );
    _replaceInState(result.intervention, isFromCache: result.isQueued);
    return result;
  }

  Future<PhotoUploadResult> uploadPhoto({
    required String interventionId,
    String? filePath,
    Uint8List? bytes,
    String type = 'photo',
    String? caption,
  }) =>
      ref.read(uploadInterventionPhotoProvider).call(
            technicianId: _technicianId,
            interventionId: interventionId,
            filePath: filePath,
            bytes: bytes,
            type: type,
            caption: caption,
          );

  Future<List<InterventionPhoto>> getPhotos(String interventionId) =>
      ref.read(interventionRepositoryProvider).getPhotos(
            technicianId: _technicianId,
            interventionId: interventionId,
          );

  void _replaceInState(Intervention updated, {required bool isFromCache}) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      InterventionLoadResult(
        interventions: [
          for (final item in current.interventions)
            if (item.id == updated.id) updated else item,
        ],
        isFromCache: isFromCache,
        cacheUpdatedAt: isFromCache ? current.cacheUpdatedAt : DateTime.now(),
      ),
    );
  }

  Future<int> syncPendingChanges() async {
    final conflicts = await ref
        .read(interventionRepositoryProvider)
        .syncPendingChanges(technicianId: _technicianId);
    await refresh();
    return conflicts;
  }
}

