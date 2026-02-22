/// API exception classes for handling HTTP errors and network failures.
///
/// This file contains exception classes for various API-related errors,
/// including HTTP status code specific exceptions and network errors.
library;

/// Base class for all API exceptions.
///
/// This exception includes the HTTP status code, error message, and
/// optional additional data returned from the API.
class ApiException implements Exception {
  /// HTTP status code (e.g., 400, 401, 404, 500)
  final int? statusCode;

  /// Error message describing what went wrong
  final String message;

  /// Additional data from the API response (optional)
  /// This can include validation errors, error codes, or other context
  final dynamic data;

  /// Stack trace for debugging purposes
  final StackTrace? stackTrace;

  /// Creates an API exception with the given parameters.
  ///
  /// [message] - A description of the error
  /// [statusCode] - The HTTP status code (optional)
  /// [data] - Additional error data from the API (optional)
  /// [stackTrace] - Stack trace for debugging (optional)
  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status Code: $statusCode)');
    }
    if (data != null) {
      buffer.write('\nAdditional Data: $data');
    }
    return buffer.toString();
  }

  /// Creates a copy of this exception with optional parameter overrides
  ApiException copyWith({
    String? message,
    int? statusCode,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return ApiException(
      message: message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
      data: data ?? this.data,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}

/// Exception thrown when there's a network connectivity issue.
///
/// This includes DNS failures, connection timeouts, no internet connection,
/// and other network-related problems.
class NetworkException extends ApiException {
  /// Creates a network exception.
  ///
  /// [message] - Description of the network error
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const NetworkException({
    super.message = 'Network error. Please check your internet connection.',
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: null,
        );

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when a request times out.
///
/// This occurs when the server doesn't respond within the configured timeout period.
class TimeoutException extends ApiException {
  /// Duration after which the request timed out
  final Duration? duration;

  /// Creates a timeout exception.
  ///
  /// [message] - Description of the timeout
  /// [duration] - How long the request waited before timing out
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const TimeoutException({
    super.message = 'Request timed out. Please try again.',
    this.duration,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 408,
        );

  @override
  String toString() {
    final buffer = StringBuffer('TimeoutException: $message');
    if (duration != null) {
      buffer.write(' (Timeout: ${duration!.inSeconds}s)');
    }
    return buffer.toString();
  }
}

/// Exception thrown for 400 Bad Request errors.
///
/// This indicates that the server cannot process the request due to
/// client error (e.g., malformed syntax, invalid request parameters).
class BadRequestException extends ApiException {
  /// Validation errors if applicable
  final Map<String, dynamic>? validationErrors;

  /// Creates a bad request exception.
  ///
  /// [message] - Description of what's wrong with the request
  /// [validationErrors] - Field-specific validation errors
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const BadRequestException({
    super.message = 'Invalid request. Please check your input.',
    this.validationErrors,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 400,
        );

  @override
  String toString() {
    final buffer = StringBuffer('BadRequestException: $message');
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      buffer.write('\nValidation Errors:');
      validationErrors!.forEach((field, error) {
        buffer.write('\n  - $field: $error');
      });
    }
    return buffer.toString();
  }

  /// Gets a formatted string of all validation errors
  String get validationErrorsString {
    if (validationErrors == null || validationErrors!.isEmpty) {
      return '';
    }
    return validationErrors!.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }
}

/// Exception thrown for 401 Unauthorized errors.
///
/// This indicates that authentication is required and has failed or
/// has not been provided.
class UnauthorizedException extends ApiException {
  /// Whether this was caused by an invalid token
  final bool isTokenInvalid;

  /// Whether this was caused by an expired token
  final bool isTokenExpired;

  /// Creates an unauthorized exception.
  ///
  /// [message] - Description of the authorization failure
  /// [isTokenInvalid] - Whether the token is invalid
  /// [isTokenExpired] - Whether the token has expired
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const UnauthorizedException({
    super.message = 'Unauthorized. Please login again.',
    this.isTokenInvalid = false,
    this.isTokenExpired = false,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 401,
        );

  @override
  String toString() {
    final buffer = StringBuffer('UnauthorizedException: $message');
    if (isTokenInvalid) {
      buffer.write(' (Invalid Token)');
    } else if (isTokenExpired) {
      buffer.write(' (Expired Token)');
    }
    return buffer.toString();
  }
}

/// Exception thrown for 403 Forbidden errors.
///
/// This indicates that the server understood the request but refuses
/// to authorize it. The user doesn't have permission for this resource.
class ForbiddenException extends ApiException {
  /// The required permission or role
  final String? requiredPermission;

  /// Creates a forbidden exception.
  ///
  /// [message] - Description of why access is forbidden
  /// [requiredPermission] - The permission/role needed to access the resource
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const ForbiddenException({
    super.message = 'Access forbidden. You do not have permission to perform this action.',
    this.requiredPermission,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 403,
        );

  @override
  String toString() {
    final buffer = StringBuffer('ForbiddenException: $message');
    if (requiredPermission != null) {
      buffer.write(' (Required: $requiredPermission)');
    }
    return buffer.toString();
  }
}

/// Exception thrown for 404 Not Found errors.
///
/// This indicates that the requested resource could not be found.
class NotFoundException extends ApiException {
  /// The resource type that was not found (e.g., "User", "Account", "Transaction")
  final String? resourceType;

  /// The ID of the resource that was not found
  final dynamic resourceId;

  /// Creates a not found exception.
  ///
  /// [message] - Description of what was not found
  /// [resourceType] - Type of resource (e.g., "User", "Account")
  /// [resourceId] - ID of the resource
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const NotFoundException({
    super.message = 'Resource not found.',
    this.resourceType,
    this.resourceId,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 404,
        );

  @override
  String toString() {
    final buffer = StringBuffer('NotFoundException: $message');
    if (resourceType != null) {
      buffer.write(' ($resourceType');
      if (resourceId != null) {
        buffer.write(' ID: $resourceId');
      }
      buffer.write(')');
    }
    return buffer.toString();
  }
}

/// Exception thrown for 409 Conflict errors.
///
/// This indicates that the request conflicts with the current state
/// of the server (e.g., duplicate resource, concurrent modification).
class ConflictException extends ApiException {
  /// The type of conflict (e.g., "duplicate", "concurrent_modification")
  final String? conflictType;

  /// The conflicting resource identifier
  final dynamic conflictingResource;

  /// Creates a conflict exception.
  ///
  /// [message] - Description of the conflict
  /// [conflictType] - Type of conflict
  /// [conflictingResource] - The resource causing the conflict
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const ConflictException({
    super.message = 'Conflict. The resource already exists or has been modified.',
    this.conflictType,
    this.conflictingResource,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 409,
        );

  @override
  String toString() {
    final buffer = StringBuffer('ConflictException: $message');
    if (conflictType != null) {
      buffer.write(' (Type: $conflictType)');
    }
    if (conflictingResource != null) {
      buffer.write(' (Resource: $conflictingResource)');
    }
    return buffer.toString();
  }
}

/// Exception thrown for 500 Internal Server Error and other 5xx errors.
///
/// This indicates that the server encountered an unexpected condition
/// that prevented it from fulfilling the request.
class ServerException extends ApiException {
  /// The specific 5xx status code
  final int serverStatusCode;

  /// Server error code if provided
  final String? errorCode;

  /// Creates a server exception.
  ///
  /// [message] - Description of the server error
  /// [serverStatusCode] - The specific 5xx status code (default: 500)
  /// [errorCode] - Server-specific error code
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const ServerException({
    super.message = 'Server error. Please try again later.',
    this.serverStatusCode = 500,
    this.errorCode,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: serverStatusCode,
        );

  @override
  String toString() {
    final buffer = StringBuffer('ServerException: $message');
    buffer.write(' (Status Code: $serverStatusCode)');
    if (errorCode != null) {
      buffer.write(' [Error Code: $errorCode]');
    }
    return buffer.toString();
  }

  /// Whether this is a 500 Internal Server Error
  bool get isInternalServerError => serverStatusCode == 500;

  /// Whether this is a 501 Not Implemented
  bool get isNotImplemented => serverStatusCode == 501;

  /// Whether this is a 502 Bad Gateway
  bool get isBadGateway => serverStatusCode == 502;

  /// Whether this is a 503 Service Unavailable
  bool get isServiceUnavailable => serverStatusCode == 503;

  /// Whether this is a 504 Gateway Timeout
  bool get isGatewayTimeout => serverStatusCode == 504;
}

/// Exception thrown for unprocessable entity errors (422).
///
/// This indicates that the server understands the content type and syntax
/// but was unable to process the contained instructions.
class UnprocessableEntityException extends ApiException {
  /// Validation or processing errors
  final Map<String, dynamic>? errors;

  /// Creates an unprocessable entity exception.
  ///
  /// [message] - Description of why the entity is unprocessable
  /// [errors] - Specific validation or processing errors
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const UnprocessableEntityException({
    super.message = 'Unable to process the request.',
    this.errors,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 422,
        );

  @override
  String toString() {
    final buffer = StringBuffer('UnprocessableEntityException: $message');
    if (errors != null && errors!.isNotEmpty) {
      buffer.write('\nErrors:');
      errors!.forEach((field, error) {
        buffer.write('\n  - $field: $error');
      });
    }
    return buffer.toString();
  }
}

/// Exception thrown for too many requests errors (429).
///
/// This indicates that the user has sent too many requests in a given
/// amount of time ("rate limiting").
class TooManyRequestsException extends ApiException {
  /// Time to wait before retrying (in seconds)
  final int? retryAfter;

  /// Creates a too many requests exception.
  ///
  /// [message] - Description of the rate limit
  /// [retryAfter] - Seconds to wait before retrying
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const TooManyRequestsException({
    super.message = 'Too many requests. Please try again later.',
    this.retryAfter,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: 429,
        );

  @override
  String toString() {
    final buffer = StringBuffer('TooManyRequestsException: $message');
    if (retryAfter != null) {
      buffer.write(' (Retry after: ${retryAfter}s)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when the response cannot be parsed.
///
/// This occurs when the API returns data in an unexpected format.
class ParseException extends ApiException {
  /// The type of data that failed to parse
  final String? dataType;

  /// Creates a parse exception.
  ///
  /// [message] - Description of the parsing error
  /// [dataType] - Type of data that failed to parse
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const ParseException({
    super.message = 'Failed to parse response data.',
    this.dataType,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: null,
        );

  @override
  String toString() {
    final buffer = StringBuffer('ParseException: $message');
    if (dataType != null) {
      buffer.write(' (Expected type: $dataType)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when an operation is cancelled.
///
/// This typically occurs when a user cancels a request or when
/// a request is cancelled programmatically.
class CancelledException extends ApiException {
  /// Creates a cancelled exception.
  ///
  /// [message] - Description of what was cancelled
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const CancelledException({
    super.message = 'Operation cancelled.',
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: null,
        );

  @override
  String toString() => 'CancelledException: $message';
}

/// Exception thrown for unknown or unexpected errors.
///
/// This is a catch-all for errors that don't fit into other categories.
class UnknownException extends ApiException {
  /// The original exception that was caught
  final Exception? originalException;

  /// Creates an unknown exception.
  ///
  /// [message] - Description of the unknown error
  /// [originalException] - The original exception that was caught
  /// [data] - Optional additional data
  /// [stackTrace] - Stack trace for debugging
  const UnknownException({
    super.message = 'An unknown error occurred.',
    this.originalException,
    super.data,
    super.stackTrace,
  }) : super(
          statusCode: null,
        );

  @override
  String toString() {
    final buffer = StringBuffer('UnknownException: $message');
    if (originalException != null) {
      buffer.write('\nOriginal Exception: $originalException');
    }
    return buffer.toString();
  }
}
