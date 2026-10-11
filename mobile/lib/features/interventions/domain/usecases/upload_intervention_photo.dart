import 'dart:typed_data';

import '../entities/photo_upload_result.dart';
import '../repositories/intervention_repository.dart';

class UploadInterventionPhoto {
  const UploadInterventionPhoto(this._repository);

  final InterventionRepository _repository;

  Future<PhotoUploadResult> call({
    required int technicianId,
    required String interventionId,
    String? filePath,
    Uint8List? bytes,
    String type = 'photo',
    String? caption,
  }) =>
      _repository.uploadPhoto(
        technicianId: technicianId,
        interventionId: interventionId,
        filePath: filePath,
        bytes: bytes,
        type: type,
        caption: caption,
      );
}

