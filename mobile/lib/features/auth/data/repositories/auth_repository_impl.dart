import 'package:dio/dio.dart';

import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _remote.currentUser(token);
      await _tokenStorage.saveUser(user.toJson());
      return user;
    } on DioException catch (error) {
      // Keep the token when the server cannot be reached. A later online retry
      // can restore the session; only an explicit unauthorized response clears it.
      if (error.response?.statusCode == 401) {
        await _tokenStorage.delete();
        return null;
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode < 500) rethrow;
      final cachedUser = await _tokenStorage.readUser();
      if (cachedUser != null) {
        return AppUserModel.fromJson(cachedUser);
      }
      rethrow;
    }
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final result = await _remote.login(email: email, password: password);
    await _tokenStorage.saveSession(
      token: result.token,
      user: result.user.toJson(),
    );
    return result.user;
  }

  @override
  Future<void> logout() async {
    final token = await _tokenStorage.read();
    if (token != null) {
      try {
        await _remote.logout(token);
      } finally {
        await _tokenStorage.delete();
      }
    }
  }
}
