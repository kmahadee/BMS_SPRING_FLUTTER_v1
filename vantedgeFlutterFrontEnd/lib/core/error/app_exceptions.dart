/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Get user-friendly message for display
  String getUserMessage() => message;

  /// Get technical message for logging
  String getTechnicalMessage() => originalError?.toString() ?? message;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (code == 'no_internet') {
      return 'No internet connection. Please check your network settings.';
    }
    if (code == 'timeout') {
      return 'Request timed out. Please try again.';
    }
    return 'Network error occurred. Please check your connection.';
  }
}

/// Server related exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (statusCode == 500) {
      return 'Server error occurred. Please try again later.';
    }
    if (statusCode == 503) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (code == 'invalid_credentials') {
      return 'Invalid username or password.';
    }
    if (code == 'session_expired') {
      return 'Your session has expired. Please login again.';
    }
    if (code == 'unauthorized') {
      return 'You are not authorized to perform this action.';
    }
    if (code == 'account_locked') {
      return 'Your account has been locked. Please contact support.';
    }
    return 'Authentication failed. Please try again.';
  }
}

/// Validation related exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return fieldErrors!.values.first;
    }
    return message;
  }
}

/// Data related exceptions
class DataException extends AppException {
  const DataException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (code == 'not_found') {
      return 'The requested data was not found.';
    }
    if (code == 'already_exists') {
      return 'This record already exists.';
    }
    if (code == 'invalid_format') {
      return 'Invalid data format. Please check your input.';
    }
    return 'Data processing error occurred.';
  }
}

/// Business logic exceptions
class BusinessException extends AppException {
  const BusinessException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() => message;
}

/// Storage related exceptions
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (code == 'storage_full') {
      return 'Device storage is full. Please free up some space.';
    }
    if (code == 'permission_denied') {
      return 'Storage permission denied. Please enable it in settings.';
    }
    return 'Storage error occurred.';
  }
}

/// Cache related exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() => 'Cache error occurred. Data may be outdated.';
}

/// File operation exceptions
class FileException extends AppException {
  const FileException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (code == 'file_not_found') {
      return 'File not found.';
    }
    if (code == 'invalid_format') {
      return 'Invalid file format.';
    }
    if (code == 'file_too_large') {
      return 'File size exceeds the maximum limit.';
    }
    return 'File operation failed.';
  }
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    return 'You don\'t have permission to perform this action.';
  }
}

/// Unknown/unexpected exceptions
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Exception factory to create appropriate exception from error
class ExceptionFactory {
  static AppException fromError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    // Handle Dio errors if using Dio
    if (error.runtimeType.toString().contains('DioException')) {
      return _handleDioError(error, stackTrace);
    }

    // Handle other common errors
    if (error.toString().contains('SocketException')) {
      return NetworkException(
        message: 'Network connection failed',
        code: 'no_internet',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('TimeoutException')) {
      return NetworkException(
        message: 'Request timeout',
        code: 'timeout',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('FormatException')) {
      return DataException(
        message: 'Invalid data format',
        code: 'invalid_format',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static AppException _handleDioError(dynamic error, StackTrace? stackTrace) {
    final response = _getResponseFromDioError(error);
    final statusCode = response?['statusCode'] as int?;
    final message = response?['message'] as String? ?? 'Request failed';

    if (statusCode == null) {
      return NetworkException(
        message: 'Network error',
        code: 'no_internet',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (statusCode >= 500) {
      return ServerException(
        message: message,
        statusCode: statusCode,
        code: 'server_error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 401) {
      return AuthException(
        message: message,
        code: 'unauthorized',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 403) {
      return PermissionException(
        message: message,
        code: 'forbidden',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 404) {
      return DataException(
        message: message,
        code: 'not_found',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 422) {
      return ValidationException(
        message: message,
        code: 'validation_failed',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return ServerException(
      message: message,
      statusCode: statusCode,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static Map<String, dynamic>? _getResponseFromDioError(dynamic error) {
    try {
      // This is a simplified version - adjust based on your actual Dio error structure
      final response = (error as dynamic).response;
      return {
        'statusCode': response?.statusCode,
        'message': response?.data?['message'] ?? response?.statusMessage,
      };
    } catch (e) {
      return null;
    }
  }
}