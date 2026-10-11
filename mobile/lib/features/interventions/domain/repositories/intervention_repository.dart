import 'dart:typed_data';

import '../entities/intervention_load_result.dart';
import '../entities/intervention.dart';
import '../entities/intervention_change_result.dart';
import '../entities/photo_upload_result.dart';
import '../entities/intervention_photo.dart';

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

  Future<PhotoUploadResult> uploadPhoto({
    required int technicianId,
    required String interventionId,
    String? filePath,
    Uint8List? bytes,
    String type = 'photo',
    String? caption,
  });

  Future<List<InterventionPhoto>> getPhotos({
    required int technicianId,
    required String interventionId,
  });

  Future<int> syncPendingChanges({required int technicianId});
}

