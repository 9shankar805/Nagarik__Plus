
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message) : super();
}

class AuthException extends AppException {
  AuthException(super.message, {super.statusCode});
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException(super.message, {super.statusCode, this.errors});
}

class ServerException extends AppException {
  ServerException(super.message, {super.statusCode});
}

class TimeoutException extends AppException {
  TimeoutException(super.message) : super();
}

class RateLimitException extends AppException {
  final int? retryAfter;

  RateLimitException(super.message, {super.statusCode, this.retryAfter});
}

