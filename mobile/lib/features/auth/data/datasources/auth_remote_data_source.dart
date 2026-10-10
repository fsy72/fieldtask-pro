import 'package:dio/dio.dart';

import '../models/app_user_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({String token, AppUserModel user})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/login',
      data: {
        'email': email,
        'password': password,
        'device_name': 'FieldTask Pro mobile',
      },
    );
    final body = response.data!;
    return (
      token: body['access_token'] as String,
      user: AppUserModel.fromJson(body['user'] as Map<String, dynamic>),
    );
  }

  Future<AppUserModel> currentUser(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return AppUserModel.fromJson(response.data!['user'] as Map<String, dynamic>);
  }

  Future<void> logout(String token) async {
    await _dio.delete<void>(
      'auth/logout',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
