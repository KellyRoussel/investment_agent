class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Unauthorized'])
      : super(statusCode: 401);
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'Network error. Please check your connection.']);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Server error. Please try again later.'])
      : super(statusCode: 500);
}

class ConflictException extends ApiException {
  ConflictException([super.message = 'Resource already exists'])
      : super(statusCode: 409);
}
