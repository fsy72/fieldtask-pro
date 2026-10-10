import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class UpdateInterventionStatus {
  const UpdateInterventionStatus(this._repository);

  final InterventionRepository _repository;

  Future<Intervention> call({
    required int technicianId,
    required Intervention intervention,
    required String status,
  }) =>
      _repository.updateStatus(
        technicianId: technicianId,
        intervention: intervention,
        status: status,
      );
}
