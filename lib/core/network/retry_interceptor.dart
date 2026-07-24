
import 'dart:async';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<int> retryableStatusCodes = const [408, 429, 500, 502, 503, 504];

  RetryInterceptor(this.dio, {this.maxRetries = 3});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      for (int i = 0; i < maxRetries; i++) {
        await Future.delayed(Duration(seconds: 1 << i)); // exponential backoff
        try {
          final response = await dio.request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            ),
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );
          return handler.resolve(response);
        } catch (e) {
          if (i == maxRetries - 1) rethrow;
        }
      }
    }
    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    if (err.response != null &&
        retryableStatusCodes.contains(err.response!.statusCode)) {
      return true;
    }
    return false;
  }
}

