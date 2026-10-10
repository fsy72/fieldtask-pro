import 'package:dio/dio.dart';

/// `API_BASE_URL` must include `/api`, for example
/// `http://10.0.2.2:8000/api/` on the Android emulator.
class ApiClient {
  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000/api/',
            ),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio dio;

  String get baseUrl => dio.options.baseUrl;
}
