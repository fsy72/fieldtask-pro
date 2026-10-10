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
