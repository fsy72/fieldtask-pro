import 'package:dio/dio.dart';

import '../../domain/entities/intervention_load_result.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../datasources/intervention_local_data_source.dart';
import '../datasources/intervention_remote_data_source.dart';

class InterventionRepositoryImpl implements InterventionRepository {
  const InterventionRepositoryImpl(this._remote, this._local);

  final InterventionRemoteDataSource _remote;
  final InterventionLocalDataSource _local;

  @override
  Future<InterventionLoadResult> getAssigned({
    required int technicianId,
  }) async {
    try {
      final remoteInterventions = await _remote.getAssigned();
      await _local.replaceForTechnician(
        technicianId: technicianId,
        interventions: remoteInterventions,
      );
      return InterventionLoadResult(
        interventions: remoteInterventions,
        isFromCache: false,
        cacheUpdatedAt: DateTime.now(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) rethrow;
      final cache = await _local.readForTechnician(technicianId);
      if (cache.interventions.isEmpty) rethrow;
      return InterventionLoadResult(
        interventions: cache.interventions,
        isFromCache: true,
        cacheUpdatedAt: cache.updatedAt,
      );
    }
  }
}
