import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/datasources/intervention_local_data_source.dart';
import '../data/datasources/intervention_remote_data_source.dart';
import '../data/repositories/intervention_repository_impl.dart';
import '../domain/entities/intervention.dart';
import '../domain/entities/intervention_load_result.dart';
import '../domain/repositories/intervention_repository.dart';
import '../domain/usecases/get_assigned_interventions.dart';
import '../domain/usecases/update_intervention_status.dart';

final connectivityStatusProvider =
    StreamProvider<List<ConnectivityResult>>((ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

final interventionRepositoryProvider = Provider<InterventionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return InterventionRepositoryImpl(
    InterventionRemoteDataSource(api.dio, tokenStorage),
    InterventionLocalDataSource(ref.watch(appDatabaseProvider)),
  );
});

final getAssignedInterventionsProvider = Provider<GetAssignedInterventions>(
  (ref) => GetAssignedInterventions(ref.watch(interventionRepositoryProvider)),
);

final updateInterventionStatusProvider = Provider<UpdateInterventionStatus>(
  (ref) => UpdateInterventionStatus(ref.watch(interventionRepositoryProvider)),
);

final interventionsControllerProvider =
    AsyncNotifierProvider<InterventionsController, InterventionLoadResult>(
  InterventionsController.new,
);

class InterventionsController extends AsyncNotifier<InterventionLoadResult> {
  late int _technicianId;

  Future<InterventionLoadResult> _load() =>
      ref.read(getAssignedInterventionsProvider).call(
            technicianId: _technicianId,
          );

  @override
  Future<InterventionLoadResult> build() {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) throw StateError('Session technicien introuvable.');
    _technicianId = user.id;
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<Intervention> updateStatus({
    required Intervention intervention,
    required String status,
  }) async {
    final updated = await ref.read(updateInterventionStatusProvider).call(
          technicianId: _technicianId,
          intervention: intervention,
          status: status,
        );
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        InterventionLoadResult(
          interventions: [
            for (final item in current.interventions)
              if (item.id == updated.id) updated else item,
          ],
          isFromCache: false,
          cacheUpdatedAt: DateTime.now(),
        ),
      );
    }
    return updated;
  }
}
