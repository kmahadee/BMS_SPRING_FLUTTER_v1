import 'dart:io';

import '../exceptions/api_exceptions.dart';
import '../exceptions/auth_exceptions.dart';

class ErrorHandler {
  ErrorHandler._();

  static ApiException mapHttpError(
    int statusCode, {
    String? message,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    final defaultMessage = _getDefaultMessageForStatusCode(statusCode);
    final errorMessage = message ?? defaultMessage;

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
          validationErrors: _extractValidationErrors(data),
        );

      case 401:
        return UnauthorizedException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
          isTokenInvalid: _isTokenInvalid(data),
          isTokenExpired: _isTokenExpired(data),
        );

      case 403:
        return ForbiddenException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
          requiredPermission: _extractRequiredPermission(data),
        );

      case 404:
        return NotFoundException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
          resourceType: _extractResourceType(data),
          resourceId: _extractResourceId(data),
        );

      case 408:
        return TimeoutException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
        );

      case 409:
        return ConflictException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
          conflictType: _extractConflictType(data),
          conflictingResource: _extractConflictingResource(data),
        );

      case 422:
        return UnprocessableEntityException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
          errors: _extractValidationErrors(data),
        );

      case 429:
        return TooManyRequestsException(
          message: errorMessage,
          data: data,
          stackTrace: stackTrace,
          retryAfter: _extractRetryAfter(data),
        );

      case >= 500 && < 600:
        return ServerException(
          message: errorMessage,
          serverStatusCode: statusCode,
          data: data,
          stackTrace: stackTrace,
          errorCode: _extractErrorCode(data),
        );

      default:
        return ApiException(
          message: errorMessage,
          statusCode: statusCode,
          data: data,
          stackTrace: stackTrace,
        );
    }
  }

  static String getUserFriendlyMessage(Exception exception) {
    if (exception is ApiException) {
      return _getApiExceptionMessage(exception);
    }

    if (exception is InvalidCredentialsException) {
      return exception.getUserMessage();
    }
    if (exception is UserAlreadyExistsException) {
      return exception.getUserMessage();
    }
    if (exception is UserNotFoundException) {
      return exception.getUserMessage();
    }
    if (exception is SessionExpiredException) {
      return exception.getUserMessage();
    }
    if (exception is TokenExpiredException) {
      return exception.getUserMessage();
    }
    if (exception is InvalidTokenException) {
      return exception.getUserMessage();
    }
    if (exception is AccountNotApprovedException) {
      return exception.getUserMessage();
    }
    if (exception is AccountLockedException) {
      return exception.getUserMessage();
    }
    if (exception is InvalidPasswordResetTokenException) {
      return exception.getUserMessage();
    }
    if (exception is IncorrectPasswordException) {
      return exception.getUserMessage();
    }
    if (exception is WeakPasswordException) {
      return exception.getUserMessage();
    }

    if (exception is SocketException) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (exception is FormatException) {
      return 'Invalid data format received. Please try again.';
    }

    if (exception is TimeoutException) {
      return exception.message ?? 'Request timed out. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String _getApiExceptionMessage(ApiException exception) {
    if (exception is NetworkException) {
      return exception.message;
    }
    if (exception is TimeoutException) {
      return exception.message;
    }
    if (exception is UnauthorizedException) {
      return 'Your session has expired. Please login again.';
    }
    if (exception is ForbiddenException) {
      return 'You do not have permission to perform this action.';
    }
    if (exception is NotFoundException) {
      return exception.resourceType != null
          ? '${exception.resourceType} not found.'
          : 'The requested resource was not found.';
    }
    if (exception is BadRequestException) {
      if (exception.validationErrors != null &&
          exception.validationErrors!.isNotEmpty) {
        return 'Please check your input:\n${exception.validationErrorsString}';
      }
      return exception.message;
    }
    if (exception is ConflictException) {
      return exception.message;
    }
    if (exception is ServerException) {
      if (exception.isServiceUnavailable) {
        return 'Service temporarily unavailable. Please try again later.';
      }
      return 'A server error occurred. Please try again later.';
    }
    if (exception is TooManyRequestsException) {
      if (exception.retryAfter != null) {
        return 'Too many requests. Please wait ${exception.retryAfter} seconds and try again.';
      }
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (exception is UnprocessableEntityException) {
      return exception.message;
    }
    if (exception is ParseException) {
      return 'Unable to process the response. Please try again.';
    }
    if (exception is CancelledException) {
      return 'Operation cancelled.';
    }
    if (exception is UnknownException) {
      return 'An unexpected error occurred. Please try again.';
    }

    return exception.message;
  }

  static String _getDefaultMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden. You do not have permission.';
      case 404:
        return 'Resource not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 409:
        return 'Conflict. The resource already exists or has been modified.';
      case 422:
        return 'Unable to process the request.';
      case 429:
        return 'Too many requests. Please try again later.';
      case >= 500 && < 600:
        return 'Server error. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  static Map<String, dynamic>? _extractValidationErrors(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      if (data.containsKey('errors') && data['errors'] is Map) {
        return Map<String, dynamic>.from(data['errors'] as Map);
      }
      if (data.containsKey('validationErrors') && data['validationErrors'] is Map) {
        return Map<String, dynamic>.from(data['validationErrors'] as Map);
      }
      if (data.containsKey('fieldErrors') && data['fieldErrors'] is Map) {
        return Map<String, dynamic>.from(data['fieldErrors'] as Map);
      }
    }

    return null;
  }

  static bool _isTokenInvalid(dynamic data) {
    if (data == null) return false;

    if (data is Map) {
      final errorType = data['errorType']?.toString().toLowerCase() ?? '';
      final message = data['message']?.toString().toLowerCase() ?? '';
      return errorType.contains('invalid_token') ||
          message.contains('invalid token') ||
          message.contains('malformed token');
    }

    return false;
  }

  static bool _isTokenExpired(dynamic data) {
    if (data == null) return false;

    if (data is Map) {
      final errorType = data['errorType']?.toString().toLowerCase() ?? '';
      final message = data['message']?.toString().toLowerCase() ?? '';
      return errorType.contains('token_expired') ||
          errorType.contains('expired_token') ||
          message.contains('token expired') ||
          message.contains('expired token');
    }

    return false;
  }

  static String? _extractRequiredPermission(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['requiredPermission']?.toString() ??
          data['required_permission']?.toString() ??
          data['requiredRole']?.toString() ??
          data['required_role']?.toString();
    }

    return null;
  }

  static String? _extractResourceType(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['resourceType']?.toString() ??
          data['resource_type']?.toString() ??
          data['type']?.toString();
    }

    return null;
  }

  static dynamic _extractResourceId(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['resourceId'] ??
          data['resource_id'] ??
          data['id'];
    }

    return null;
  }

  static String? _extractConflictType(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['conflictType']?.toString() ??
          data['conflict_type']?.toString() ??
          data['type']?.toString();
    }

    return null;
  }

  static dynamic _extractConflictingResource(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['conflictingResource'] ??
          data['conflicting_resource'] ??
          data['existingValue'] ??
          data['existing_value'];
    }

    return null;
  }

  static int? _extractRetryAfter(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final retryAfter = data['retryAfter'] ?? data['retry_after'];
      if (retryAfter is int) return retryAfter;
      if (retryAfter is String) return int.tryParse(retryAfter);
    }

    return null;
  }

  static String? _extractErrorCode(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['errorCode']?.toString() ??
          data['error_code']?.toString() ??
          data['code']?.toString();
    }

    return null;
  }

  static bool shouldLogout(Exception exception) {
    if (exception is UnauthorizedException) return true;
    if (exception is SessionExpiredException) return true;
    if (exception is TokenExpiredException && exception.isRefreshToken) return true;
    if (exception is InvalidTokenException) return true;
    if (exception is AccountLockedException) return true;

    return false;
  }

  static bool isRetryable(Exception exception) {
    if (exception is NetworkException) return true;
    if (exception is TimeoutException) return true;
    if (exception is ServerException) {
      return exception.serverStatusCode >= 502;
    }

    return false;
  }

  static Duration? getRetryDelay(Exception exception, {int attempt = 1}) {
    if (!isRetryable(exception)) return null;

    if (exception is TooManyRequestsException && exception.retryAfter != null) {
      return Duration(seconds: exception.retryAfter!);
    }

    final seconds = (1 << attempt).clamp(1, 32);
    return Duration(seconds: seconds);
  }

  static void logException(
    Exception exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    print('=== Exception Logged ===');
    print('Type: ${exception.runtimeType}');
    print('Message: $exception');
    
    if (exception is ApiException && exception.statusCode != null) {
      print('Status Code: ${exception.statusCode}');
    }
    
    if (context != null && context.isNotEmpty) {
      print('Context: $context');
    }
    
    if (stackTrace != null) {
      print('Stack Trace:\n$stackTrace');
    }
    
    print('========================');

  }
}
