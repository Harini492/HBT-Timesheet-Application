/// App-level exception types surfaced to the UI layer as readable messages.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Network error. Check your connection.'])
      : super(message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'Session expired. Please log in again.'])
      : super(message, statusCode: 401);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, statusCode: 422);
}

class ServerException extends AppException {
  const ServerException([String message = 'Something went wrong. Please try again.'])
      : super(message, statusCode: 500);
}
