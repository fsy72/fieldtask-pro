import '../entities/intervention_load_result.dart';
import '../entities/intervention.dart';

abstract interface class InterventionRepository {
  Future<InterventionLoadResult> getAssigned({required int technicianId});

  Future<Intervention> updateStatus({
    required int technicianId,
    required Intervention intervention,
    required String status,
  });
}
