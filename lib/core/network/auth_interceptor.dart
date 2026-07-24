import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env_config.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(baseUrl: EnvConfig.baseUrl));
          final refreshResponse = await dio.post(
            '/auth/refresh',
            options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final data = refreshResponse.data;
            final newToken = data['token'] ?? data['data']?['token'];
            if (newToken != null) {
              await _storage.write(key: 'auth_token', value: newToken.toString());
              if (data['refresh_token'] != null) {
                await _storage.write(key: 'refresh_token', value: data['refresh_token'].toString());
              }

              final requestOptions = err.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newToken';

              final retryResponse = await dio.fetch(requestOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Token refresh failed, clean tokens
          await _storage.delete(key: 'auth_token');
          await _storage.delete(key: 'refresh_token');
        }
      } else {
        await _storage.delete(key: 'auth_token');
      }
    }
    super.onError(err, handler);
  }
}
