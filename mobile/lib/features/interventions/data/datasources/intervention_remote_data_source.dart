import 'package:dio/dio.dart';

import '../../../../core/storage/token_storage.dart';
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
}
