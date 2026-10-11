import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/intervention_model.dart';

class InterventionLocalDataSource {
  const InterventionLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> replaceForTechnician({
    required int technicianId,
    required List<InterventionModel> interventions,
  }) async {
    final db = await _appDatabase.database;
    final syncedAt = DateTime.now().toIso8601String();
    await db.transaction((transaction) async {
      await transaction.delete(
        'interventions',
        where: 'technician_id = ?',
        whereArgs: [technicianId],
      );
      final batch = transaction.batch();
      for (final intervention in interventions) {
        batch.insert(
          'interventions',
          intervention.toDatabase(technicianId: technicianId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (interventions.isNotEmpty) {
        await batch.commit(noResult: true);
      }
      await transaction.insert(
        'app_meta',
        {'key': _syncKey(technicianId), 'value': syncedAt},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> saveForTechnician({
    required int technicianId,
    required InterventionModel intervention,
  }) async {
    final db = await _appDatabase.database;
    await db.insert(
      'interventions',
      intervention.toDatabase(technicianId: technicianId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> queueStatusUpdate({
    required int technicianId,
    required InterventionModel intervention,
    required String status,
  }) async {
    final db = await _appDatabase.database;
    await db.transaction((transaction) async {
      final existing = await transaction.query(
        'intervention_status_updates',
        columns: ['sync_version', 'notes', 'includes_notes'],
        where: 'intervention_id = ? AND technician_id = ?',
        whereArgs: [intervention.id, technicianId],
        limit: 1,
      );
      final baseVersion = existing.isEmpty
          ? intervention.syncVersion
          : existing.first['sync_version']! as int;
      await transaction.insert(
        'intervention_status_updates',
        {
          'intervention_id': intervention.id,
          'technician_id': technicianId,
          'status': status,
          'sync_version': baseVersion,
          'is_conflict': 0,
          'notes': existing.isEmpty ? null : existing.first['notes'],
          'includes_notes':
              existing.isEmpty ? 0 : existing.first['includes_notes'],
          'queued_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.insert(
        'interventions',
        intervention
            .copyWith(status: status, syncVersion: baseVersion)
            .toDatabase(technicianId: technicianId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> queueNotesUpdate({
    required int technicianId,
    required InterventionModel intervention,
    required String? notes,
  }) async {
    final db = await _appDatabase.database;
    await db.transaction((transaction) async {
      final existing = await transaction.query(
        'intervention_status_updates',
        columns: ['sync_version'],
        where: 'intervention_id = ? AND technician_id = ?',
        whereArgs: [intervention.id, technicianId],
        limit: 1,
      );
      final baseVersion = existing.isEmpty
          ? intervention.syncVersion
          : existing.first['sync_version']! as int;
      await transaction.insert(
        'intervention_status_updates',
        {
          'intervention_id': intervention.id,
          'technician_id': technicianId,
          'status': intervention.status,
          'sync_version': baseVersion,
          'is_conflict': 0,
          'notes': notes,
          'includes_notes': 1,
          'queued_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.insert(
        'interventions',
        intervention
            .copyWith(notes: notes, clearNotes: notes == null, syncVersion: baseVersion)
            .toDatabase(technicianId: technicianId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<Map<String, Object?>>> pendingChanges(
    int technicianId,
  ) async {
    final db = await _appDatabase.database;
    return db.query(
      'intervention_status_updates',
      where: 'technician_id = ? AND is_conflict = 0',
      whereArgs: [technicianId],
      orderBy: 'queued_at ASC',
    );
  }

  Future<Map<String, Object?>?> pendingChange({
    required int technicianId,
    required String interventionId,
  }) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'intervention_status_updates',
      where: 'technician_id = ? AND intervention_id = ?',
      whereArgs: [technicianId, interventionId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> resolvePendingChange({
    required int technicianId,
    required InterventionModel intervention,
  }) async {
    final db = await _appDatabase.database;
    await db.transaction((transaction) async {
      await transaction.insert(
        'interventions',
        intervention.toDatabase(technicianId: technicianId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.delete(
        'intervention_status_updates',
        where: 'intervention_id = ? AND technician_id = ?',
        whereArgs: [intervention.id, technicianId],
      );
    });
  }

  Future<void> markChangeConflict({
    required int technicianId,
    required String interventionId,
  }) async {
    final db = await _appDatabase.database;
    await db.update(
      'intervention_status_updates',
      {'is_conflict': 1},
      where: 'intervention_id = ? AND technician_id = ?',
      whereArgs: [interventionId, technicianId],
    );
  }

  Future<String> queuePhoto({
    required int technicianId,
    required String interventionId,
    required String clientUuid,
    required String sourcePath,
    String? caption,
  }) async {
    final databasesPath = await getDatabasesPath();
    final queueDirectory = Directory(path.join(databasesPath, 'pending_photos'));
    await queueDirectory.create(recursive: true);
    final extension = path.extension(sourcePath).isEmpty
        ? '.jpg'
        : path.extension(sourcePath).toLowerCase();
    final savedPath = path.join(queueDirectory.path, '$clientUuid$extension');
    await File(sourcePath).copy(savedPath);
    try {
      final db = await _appDatabase.database;
      await db.insert('pending_attachments', {
        'client_uuid': clientUuid,
        'technician_id': technicianId,
        'intervention_id': interventionId,
        'file_path': savedPath,
        'caption': caption,
        'queued_at': DateTime.now().toIso8601String(),
      });
      return savedPath;
    } catch (_) {
      try {
        await File(savedPath).delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> pendingPhotos(int technicianId) async {
    final db = await _appDatabase.database;
    return db.query(
      'pending_attachments',
      where: 'technician_id = ?',
      whereArgs: [technicianId],
      orderBy: 'queued_at ASC',
    );
  }

  Future<void> removePendingPhoto(String clientUuid) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'pending_attachments',
      columns: ['file_path'],
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
      limit: 1,
    );
    await db.delete(
      'pending_attachments',
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
    if (rows.isNotEmpty) {
      final file = File(rows.first['file_path']! as String);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  Future<({List<InterventionModel> interventions, DateTime? updatedAt})>
      readForTechnician(int technicianId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'interventions',
      where: 'technician_id = ?',
      whereArgs: [technicianId],
      orderBy: 'priority DESC, scheduled_at ASC',
    );
    final metadata = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [_syncKey(technicianId)],
      limit: 1,
    );
    return (
      interventions: rows.map(InterventionModel.fromDatabase).toList(),
      updatedAt: metadata.isEmpty
          ? null
          : DateTime.tryParse(metadata.first['value']! as String),
    );
  }

  String _syncKey(int technicianId) => 'interventions_synced_$technicianId';
}
