/// Authentication-specific exception classes.
///
/// This file contains exception classes for authentication and
/// authorization related errors in the banking application.
library;

/// Exception thrown when user credentials are invalid.
///
/// This occurs during login when the username or password is incorrect.
class InvalidCredentialsException implements Exception {
  /// Error message describing the invalid credentials
  final String message;

  /// Number of failed login attempts (if tracked)
  final int? failedAttempts;

  /// Maximum allowed attempts before lockout
  final int? maxAttempts;

  /// Whether the account is locked due to too many failed attempts
  final bool isAccountLocked;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates an invalid credentials exception.
  ///
  /// [message] - Description of the invalid credentials error
  /// [failedAttempts] - Number of failed login attempts
  /// [maxAttempts] - Maximum allowed attempts
  /// [isAccountLocked] - Whether the account is locked
  /// [stackTrace] - Stack trace for debugging
  const InvalidCredentialsException({
    this.message = 'Invalid username or password.',
    this.failedAttempts,
    this.maxAttempts,
    this.isAccountLocked = false,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('InvalidCredentialsException: $message');
    if (isAccountLocked) {
      buffer.write(' (Account Locked)');
    } else if (failedAttempts != null && maxAttempts != null) {
      buffer.write(' (Attempts: $failedAttempts/$maxAttempts)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message including lockout information
  String getUserMessage() {
    if (isAccountLocked) {
      return 'Your account has been locked due to too many failed login attempts. Please contact support.';
    } else if (failedAttempts != null && maxAttempts != null) {
      final remaining = maxAttempts! - failedAttempts!;
      if (remaining > 0) {
        return '$message You have $remaining attempt${remaining > 1 ? 's' : ''} remaining.';
      }
      return message;
    }
    return message;
  }
}

/// Exception thrown when attempting to register with an existing username/email.
///
/// This occurs during registration when the username or email already exists.
class UserAlreadyExistsException implements Exception {
  /// Error message describing the conflict
  final String message;

  /// The field that already exists (e.g., "username", "email")
  final String? existingField;

  /// The value that already exists
  final String? existingValue;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates a user already exists exception.
  ///
  /// [message] - Description of the conflict
  /// [existingField] - The field that already exists
  /// [existingValue] - The value that already exists
  /// [stackTrace] - Stack trace for debugging
  const UserAlreadyExistsException({
    this.message = 'User already exists.',
    this.existingField,
    this.existingValue,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('UserAlreadyExistsException: $message');
    if (existingField != null) {
      buffer.write(' (Field: $existingField');
      if (existingValue != null) {
        buffer.write(', Value: $existingValue');
      }
      buffer.write(')');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message specifying which field already exists
  String getUserMessage() {
    if (existingField != null) {
      return 'A user with this ${existingField!} already exists.';
    }
    return message;
  }
}

/// Exception thrown when a user cannot be found.
///
/// This can occur during password reset, profile lookup, or other operations
/// that require an existing user.
class UserNotFoundException implements Exception {
  /// Error message describing that the user was not found
  final String message;

  /// The identifier used to search for the user (username, email, ID)
  final String? identifier;

  /// The type of identifier (e.g., "username", "email", "id")
  final String? identifierType;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates a user not found exception.
  ///
  /// [message] - Description of the error
  /// [identifier] - The value used to search for the user
  /// [identifierType] - The type of identifier
  /// [stackTrace] - Stack trace for debugging
  const UserNotFoundException({
    this.message = 'User not found.',
    this.identifier,
    this.identifierType,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('UserNotFoundException: $message');
    if (identifierType != null && identifier != null) {
      buffer.write(' ($identifierType: $identifier)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message
  String getUserMessage() {
    if (identifierType != null) {
      return 'No user found with the provided $identifierType.';
    }
    return message;
  }
}

/// Exception thrown when a user's session has expired.
///
/// This occurs when the user's authentication session is no longer valid,
/// typically due to inactivity or reaching the session expiration time.
class SessionExpiredException implements Exception {
  /// Error message describing the expired session
  final String message;

  /// When the session expired (timestamp)
  final DateTime? expiryTime;

  /// Duration of inactivity that caused expiration
  final Duration? inactivityDuration;

  /// Whether this was due to inactivity vs. time limit
  final bool isDueToInactivity;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates a session expired exception.
  ///
  /// [message] - Description of the expired session
  /// [expiryTime] - When the session expired
  /// [inactivityDuration] - How long the user was inactive
  /// [isDueToInactivity] - Whether this was caused by inactivity
  /// [stackTrace] - Stack trace for debugging
  const SessionExpiredException({
    this.message = 'Your session has expired. Please login again.',
    this.expiryTime,
    this.inactivityDuration,
    this.isDueToInactivity = false,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('SessionExpiredException: $message');
    if (isDueToInactivity && inactivityDuration != null) {
      buffer.write(' (Inactive for ${inactivityDuration!.inMinutes} minutes)');
    } else if (expiryTime != null) {
      buffer.write(' (Expired at: $expiryTime)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message explaining why the session expired
  String getUserMessage() {
    if (isDueToInactivity) {
      return 'Your session has expired due to inactivity. Please login again.';
    }
    return message;
  }
}

/// Exception thrown when an authentication token has expired.
///
/// This occurs when the JWT access token or refresh token has expired.
class TokenExpiredException implements Exception {
  /// Error message describing the expired token
  final String message;

  /// Type of token that expired (e.g., "access", "refresh")
  final String tokenType;

  /// When the token expired
  final DateTime? expiryTime;

  /// Whether the token can be refreshed
  final bool canRefresh;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates a token expired exception.
  ///
  /// [message] - Description of the expired token
  /// [tokenType] - Type of token (access or refresh)
  /// [expiryTime] - When the token expired
  /// [canRefresh] - Whether a refresh is possible
  /// [stackTrace] - Stack trace for debugging
  const TokenExpiredException({
    this.message = 'Authentication token has expired.',
    this.tokenType = 'access',
    this.expiryTime,
    this.canRefresh = false,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('TokenExpiredException: $message');
    buffer.write(' (Token Type: $tokenType)');
    if (expiryTime != null) {
      buffer.write(' (Expired at: $expiryTime)');
    }
    if (canRefresh) {
      buffer.write(' (Can Refresh)');
    }
    return buffer.toString();
  }

  /// Whether this is an access token expiration
  bool get isAccessToken => tokenType.toLowerCase() == 'access';

  /// Whether this is a refresh token expiration
  bool get isRefreshToken => tokenType.toLowerCase() == 'refresh';

  /// Gets a user-friendly message
  String getUserMessage() {
    if (isRefreshToken || !canRefresh) {
      return 'Your session has expired. Please login again.';
    }
    return 'Your authentication has expired. Refreshing...';
  }
}

/// Exception thrown when a token is invalid or malformed.
///
/// This occurs when the JWT token cannot be decoded or verified.
class InvalidTokenException implements Exception {
  /// Error message describing the invalid token
  final String message;

  /// Type of token that is invalid
  final String tokenType;

  /// Reason why the token is invalid
  final String? reason;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates an invalid token exception.
  ///
  /// [message] - Description of the invalid token
  /// [tokenType] - Type of token (access or refresh)
  /// [reason] - Specific reason for invalidity
  /// [stackTrace] - Stack trace for debugging
  const InvalidTokenException({
    this.message = 'Invalid authentication token.',
    this.tokenType = 'access',
    this.reason,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('InvalidTokenException: $message');
    buffer.write(' (Token Type: $tokenType)');
    if (reason != null) {
      buffer.write(' (Reason: $reason)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message
  String getUserMessage() {
    return 'Your authentication is invalid. Please login again.';
  }
}

/// Exception thrown when user account is not approved/activated.
///
/// This occurs when trying to login with an account that hasn't been
/// approved by an administrator yet.
class AccountNotApprovedException implements Exception {
  /// Error message describing the pending approval
  final String message;

  /// User ID of the pending account
  final int? userId;

  /// Username of the pending account
  final String? username;

  /// Account status (e.g., "PENDING", "INACTIVE")
  final String? status;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates an account not approved exception.
  ///
  /// [message] - Description of the pending status
  /// [userId] - ID of the user
  /// [username] - Username of the user
  /// [status] - Current account status
  /// [stackTrace] - Stack trace for debugging
  const AccountNotApprovedException({
    this.message = 'Your account is pending approval.',
    this.userId,
    this.username,
    this.status,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AccountNotApprovedException: $message');
    if (username != null) {
      buffer.write(' (Username: $username)');
    }
    if (status != null) {
      buffer.write(' (Status: $status)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message
  String getUserMessage() {
    return 'Your account is pending approval. Please wait for an administrator to approve your account.';
  }
}

/// Exception thrown when user account is locked or suspended.
///
/// This occurs when trying to access an account that has been locked
/// due to security reasons or administrative action.
class AccountLockedException implements Exception {
  /// Error message describing the locked account
  final String message;

  /// Reason for the account lock
  final String? reason;

  /// When the account was locked
  final DateTime? lockedAt;

  /// When the account will be unlocked (if temporary)
  final DateTime? unlockAt;

  /// Whether the lock is permanent
  final bool isPermanent;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates an account locked exception.
  ///
  /// [message] - Description of the locked account
  /// [reason] - Reason for locking
  /// [lockedAt] - When the account was locked
  /// [unlockAt] - When the account will be unlocked
  /// [isPermanent] - Whether the lock is permanent
  /// [stackTrace] - Stack trace for debugging
  const AccountLockedException({
    this.message = 'Your account has been locked.',
    this.reason,
    this.lockedAt,
    this.unlockAt,
    this.isPermanent = false,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AccountLockedException: $message');
    if (reason != null) {
      buffer.write(' (Reason: $reason)');
    }
    if (isPermanent) {
      buffer.write(' (Permanent)');
    } else if (unlockAt != null) {
      buffer.write(' (Unlocks at: $unlockAt)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message
  String getUserMessage() {
    if (isPermanent) {
      return 'Your account has been permanently locked. Please contact support for assistance.';
    } else if (unlockAt != null) {
      final now = DateTime.now();
      if (unlockAt!.isAfter(now)) {
        final difference = unlockAt!.difference(now);
        if (difference.inHours > 0) {
          return 'Your account is locked. It will be unlocked in ${difference.inHours} hours.';
        } else if (difference.inMinutes > 0) {
          return 'Your account is locked. It will be unlocked in ${difference.inMinutes} minutes.';
        }
      }
    }
    return '$message Please contact support if you need assistance.';
  }
}

/// Exception thrown when password reset token is invalid or expired.
///
/// This occurs during the password reset process.
class InvalidPasswordResetTokenException implements Exception {
  /// Error message describing the invalid token
  final String message;

  /// Whether the token has expired
  final bool isExpired;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates an invalid password reset token exception.
  ///
  /// [message] - Description of the invalid token
  /// [isExpired] - Whether the token has expired
  /// [stackTrace] - Stack trace for debugging
  const InvalidPasswordResetTokenException({
    this.message = 'Invalid or expired password reset token.',
    this.isExpired = false,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('InvalidPasswordResetTokenException: $message');
    if (isExpired) {
      buffer.write(' (Expired)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message
  String getUserMessage() {
    if (isExpired) {
      return 'This password reset link has expired. Please request a new one.';
    }
    return 'This password reset link is invalid. Please request a new one.';
  }
}

/// Exception thrown when attempting to change password with incorrect current password.
class IncorrectPasswordException implements Exception {
  /// Error message describing the incorrect password
  final String message;

  /// Number of failed attempts
  final int? failedAttempts;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates an incorrect password exception.
  ///
  /// [message] - Description of the error
  /// [failedAttempts] - Number of failed attempts
  /// [stackTrace] - Stack trace for debugging
  const IncorrectPasswordException({
    this.message = 'Current password is incorrect.',
    this.failedAttempts,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('IncorrectPasswordException: $message');
    if (failedAttempts != null) {
      buffer.write(' (Failed Attempts: $failedAttempts)');
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message
  String getUserMessage() => message;
}

/// Exception thrown when new password doesn't meet requirements.
class WeakPasswordException implements Exception {
  /// Error message describing the weak password
  final String message;

  /// List of requirements that weren't met
  final List<String>? failedRequirements;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Creates a weak password exception.
  ///
  /// [message] - Description of the weak password
  /// [failedRequirements] - Requirements that weren't met
  /// [stackTrace] - Stack trace for debugging
  const WeakPasswordException({
    this.message = 'Password does not meet security requirements.',
    this.failedRequirements,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('WeakPasswordException: $message');
    if (failedRequirements != null && failedRequirements!.isNotEmpty) {
      buffer.write('\nRequirements not met:');
      for (final requirement in failedRequirements!) {
        buffer.write('\n  - $requirement');
      }
    }
    return buffer.toString();
  }

  /// Gets a user-friendly message with requirements
  String getUserMessage() {
    if (failedRequirements != null && failedRequirements!.isNotEmpty) {
      return '$message\n${failedRequirements!.join('\n')}';
    }
    return message;
  }
}
