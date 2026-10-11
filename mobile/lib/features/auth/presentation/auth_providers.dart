import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_use_case.dart';
import '../domain/usecases/logout_use_case.dart';
import '../domain/usecases/restore_session_use_case.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(apiClientProvider).dio),
    ref.watch(tokenStorageProvider),
  ),
);

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>(
  (ref) => RestoreSessionUseCase(ref.watch(authRepositoryProvider)),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() => ref.read(restoreSessionUseCaseProvider).call();

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(loginUseCaseProvider).call(email: email, password: password),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(logoutUseCaseProvider).call();
      return null;
    });
  }
}
