import '../entities/intervention_load_result.dart';
import '../repositories/intervention_repository.dart';

class GetAssignedInterventions {
  const GetAssignedInterventions(this._repository);

  final InterventionRepository _repository;

  Future<InterventionLoadResult> call({required int technicianId}) =>
      _repository.getAssigned(technicianId: technicianId);
}
