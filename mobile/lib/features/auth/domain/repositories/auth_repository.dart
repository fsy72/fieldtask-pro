import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> restoreSession();

  Future<AppUser> login({required String email, required String password});

  Future<void> logout();
}
