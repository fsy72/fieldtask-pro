import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/intervention.dart';
import '../../domain/entities/intervention_photo.dart';
import '../models/intervention_model.dart';

class InterventionRemoteDataSource {
  const InterventionRemoteDataSource(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<List<InterventionModel>> getAssigned() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      throw StateError('Aucun jeton de session disponible.');
    }

    final interventions = <InterventionModel>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _dio.get<Map<String, dynamic>>(
        'interventions',
        queryParameters: {
          'per_page': 100,
          'priority': 'desc',
          'page': page,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = response.data!;
      final data = body['data'] as List<dynamic>? ?? const [];
      interventions.addAll(
        data.map((item) => InterventionModel.fromJson(
              item as Map<String, dynamic>,
            )),
      );
      final meta = body['meta'] as Map<String, dynamic>?;
      lastPage = (meta?['last_page'] as num?)?.toInt() ?? page;
      page++;
    } while (page <= lastPage);

    return interventions;
  }

  Future<InterventionModel> updateIntervention({
    required Intervention intervention,
    required String status,
    String? notes,
    bool includeNotes = false,
  }) async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      throw StateError('Aucun jeton de session disponible.');
    }

    final payload = <String, dynamic>{
      'status': status,
      'sync_version': intervention.syncVersion,
    };
    if (includeNotes) payload['notes'] = notes;

    final response = await _dio.patch<Map<String, dynamic>>(
      'interventions/${intervention.id}',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final body = response.data!;
    final responseData = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
    return InterventionModel.fromJson(responseData);
  }

  Future<void> uploadPhoto({
    required String interventionId,
    required String clientUuid,
    required String filePath,
    String? caption,
  }) async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      throw StateError('Aucun jeton de session disponible.');
    }

    final form = FormData.fromMap({
      'client_uuid': clientUuid,
      'type': 'photo',
      'file': await MultipartFile.fromFile(
        filePath,
        filename: path.basename(filePath),
      ),
      if (caption != null && caption.trim().isNotEmpty)
        'caption': caption.trim(),
    });
    await _dio.post<void>(
      'interventions/$interventionId/attachments',
      data: form,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<InterventionPhoto>> getPhotos({
    required String interventionId,
  }) async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      throw StateError('Aucun jeton de session disponible.');
    }
    final options = Options(headers: {'Authorization': 'Bearer $token'});
    final response = await _dio.get<Map<String, dynamic>>(
      'interventions/$interventionId',
      options: options,
    );
    final body = response.data!;
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
    final attachments = data['attachments'] as List<dynamic>? ?? const [];
    final photos = <InterventionPhoto>[];
    for (final item in attachments) {
      if (item is! Map<String, dynamic> || item['type'] != 'photo') continue;
      final id = item['id'].toString();
      final image = await _dio.get<List<int>>(
        'interventions/$interventionId/attachments/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );
      photos.add(InterventionPhoto(
        id: id,
        bytes: Uint8List.fromList(image.data!),
        caption: item['caption'] as String?,
      ));
    }
    return photos;
  }
}
