
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';
import 'error_handler.dart';
import 'api_response.dart';
import '../config/env_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(_storage),
      RetryInterceptor(_dio),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  void setLanguageHeader(String lang) {
    _dio.options.headers['Accept-Language'] = lang;
  }

  Dio get dio => _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response.data, fromJsonT);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response.data, fromJsonT);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(response.data, fromJsonT);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<ApiResponse<void>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse<void>.fromJson(response.data, null);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<ApiResponse<T>> upload<T>(
    String path, {
    required FormData data,
    T Function(dynamic)? fromJsonT,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        onSendProgress: onSendProgress,
      );
      return ApiResponse<T>.fromJson(response.data, fromJsonT);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}

