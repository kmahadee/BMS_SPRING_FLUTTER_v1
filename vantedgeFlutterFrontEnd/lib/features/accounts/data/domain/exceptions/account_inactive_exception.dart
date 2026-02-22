import 'package:vantedge/core/exceptions/api_exceptions.dart';

/// Exception thrown when attempting operations on an inactive account
/// 
/// This exception is thrown when trying to perform transactions or operations
/// on an account that is in an inactive, dormant, or blocked state.
class AccountInactiveException extends ForbiddenException {
  /// The account number that is inactive
  final String? accountNumber;
  
  /// The current status of the account (INACTIVE, DORMANT, BLOCKED)
  final String? accountStatus;

  const AccountInactiveException({
    super.message = 'Account is not active and cannot perform this operation',
    this.accountNumber,
    this.accountStatus,
    super.data,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AccountInactiveException: $message');
    if (accountNumber != null) {
      buffer.write(' (Account Number: $accountNumber)');
    }
    if (accountStatus != null) {
      buffer.write(' (Status: $accountStatus)');
    }
    if (data != null) {
      buffer.write('\nAdditional Data: $data');
    }
    return buffer.toString();
  }

  /// Create AccountInactiveException with custom message
  factory AccountInactiveException.withMessage(String message, {
    String? accountNumber,
    String? accountStatus,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return AccountInactiveException(
      message: message,
      accountNumber: accountNumber,
      accountStatus: accountStatus,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Create AccountInactiveException for specific account
  factory AccountInactiveException.forAccount(
    String accountNumber,
    String accountStatus, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return AccountInactiveException(
      message: customMessage ?? 
          'Account $accountNumber is $accountStatus and cannot perform operations',
      accountNumber: accountNumber,
      accountStatus: accountStatus,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Create exception for blocked account
  factory AccountInactiveException.blocked(String accountNumber, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return AccountInactiveException(
      message: customMessage ?? 
          'Account $accountNumber is blocked. Please contact support.',
      accountNumber: accountNumber,
      accountStatus: 'BLOCKED',
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Create exception for dormant account
  factory AccountInactiveException.dormant(String accountNumber, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return AccountInactiveException(
      message: customMessage ?? 
          'Account $accountNumber is dormant. Please reactivate your account.',
      accountNumber: accountNumber,
      accountStatus: 'DORMANT',
      data: data,
      stackTrace: stackTrace,
    );
  }
}