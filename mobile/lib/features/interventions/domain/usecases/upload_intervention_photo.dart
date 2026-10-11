import '../entities/photo_upload_result.dart';
import '../repositories/intervention_repository.dart';

class UploadInterventionPhoto {
  const UploadInterventionPhoto(this._repository);

  final InterventionRepository _repository;

  Future<PhotoUploadResult> call({
    required int technicianId,
    required String interventionId,
    required String filePath,
    String? caption,
  }) =>
      _repository.uploadPhoto(
        technicianId: technicianId,
        interventionId: interventionId,
        filePath: filePath,
        caption: caption,
      );
}
