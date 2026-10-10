import '../entities/intervention_load_result.dart';

abstract interface class InterventionRepository {
  Future<InterventionLoadResult> getAssigned({required int technicianId});
}
