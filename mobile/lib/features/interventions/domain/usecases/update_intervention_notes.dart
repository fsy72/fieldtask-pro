import '../entities/intervention.dart';
import '../entities/intervention_change_result.dart';
import '../repositories/intervention_repository.dart';

class UpdateInterventionNotes {
  const UpdateInterventionNotes(this._repository);

  final InterventionRepository _repository;

  Future<InterventionChangeResult> call({
    required int technicianId,
    required Intervention intervention,
    required String? notes,
  }) =>
      _repository.updateNotes(
        technicianId: technicianId,
        intervention: intervention,
        notes: notes,
      );
}
