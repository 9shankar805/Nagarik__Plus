
import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException('Connection timed out');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          if (statusCode == 401 || statusCode == 403) {
            return AuthException(
              responseData?['message'] ?? 'Unauthorized',
              statusCode: statusCode,
            );
          } else if (statusCode == 422) {
            return ValidationException(
              responseData?['message'] ?? 'Validation failed',
              statusCode: statusCode,
              errors: responseData?['errors'],
            );
          } else if (statusCode == 429) {
            final retryAfter =
                error.response?.headers['retry-after']?.first;
            return RateLimitException(
              'Too many requests',
              statusCode: statusCode,
              retryAfter: retryAfter != null ? int.tryParse(retryAfter) : null,
            );
          } else if (statusCode! >= 500) {
            return ServerException(
              responseData?['message'] ?? 'Server error',
              statusCode: statusCode,
            );
          } else {
            return AppException(
              responseData?['message'] ?? 'Something went wrong',
              statusCode: statusCode,
            );
          }
        case DioExceptionType.cancel:
          return AppException('Request cancelled');
        case DioExceptionType.connectionError:
          return NetworkException('No internet connection');
        case DioExceptionType.unknown:
          return NetworkException('Network error');
        default:
          return AppException('Unknown error');
      }
    }
    return AppException(error.toString());
  }
}

