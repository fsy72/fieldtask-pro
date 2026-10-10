import '../entities/intervention_load_result.dart';
import '../entities/intervention.dart';
import '../entities/intervention_change_result.dart';

abstract interface class InterventionRepository {
  Future<InterventionLoadResult> getAssigned({required int technicianId});

  Future<InterventionChangeResult> updateStatus({
    required int technicianId,
    required Intervention intervention,
    required String status,
  });

  Future<InterventionChangeResult> updateNotes({
    required int technicianId,
    required Intervention intervention,
    required String? notes,
  });

  Future<int> syncPendingChanges({required int technicianId});
}
