import 'package:vantedge/core/exceptions/api_exceptions.dart';

/// Exception thrown when an account is not found in the system
/// 
/// This exception is typically thrown when attempting to access
/// an account that doesn't exist or the user doesn't have permission to view.
class AccountNotFoundException extends NotFoundException {
  /// The account number that was not found
  final String? accountNumber;

  const AccountNotFoundException({
    super.message = 'Account not found',
    this.accountNumber,
    super.data,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AccountNotFoundException: $message');
    if (accountNumber != null) {
      buffer.write(' (Account Number: $accountNumber)');
    }
    if (data != null) {
      buffer.write('\nAdditional Data: $data');
    }
    return buffer.toString();
  }

  /// Create AccountNotFoundException with custom message
  factory AccountNotFoundException.withMessage(String message, {
    String? accountNumber,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return AccountNotFoundException(
      message: message,
      accountNumber: accountNumber,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Create AccountNotFoundException for specific account number
  factory AccountNotFoundException.forAccount(String accountNumber, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return AccountNotFoundException(
      message: customMessage ?? 'Account $accountNumber not found',
      accountNumber: accountNumber,
      data: data,
      stackTrace: stackTrace,
    );
  }
}