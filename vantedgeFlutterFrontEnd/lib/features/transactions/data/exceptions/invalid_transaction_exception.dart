import 'package:vantedge/core/exceptions/api_exceptions.dart';

class InvalidTransactionException extends BadRequestException {
  final String? violatedRule;

  const InvalidTransactionException({
    super.message = 'The transaction request is invalid.',
    this.violatedRule,
    super.data,
    super.stackTrace,
  });


  factory InvalidTransactionException.withMessage(
    String message, {
    String? violatedRule,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return InvalidTransactionException(
      message: message,
      violatedRule: violatedRule,
      data: data,
      stackTrace: stackTrace,
    );
  }

  factory InvalidTransactionException.sameAccount({
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return InvalidTransactionException(
      message:
          'Source and destination accounts cannot be the same. '
          'Please select a different destination account.',
      violatedRule: 'SAME_ACCOUNT',
      data: data,
      stackTrace: stackTrace,
    );
  }

  factory InvalidTransactionException.invalidAmount({
    double? amount,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return InvalidTransactionException(
      message: amount != null
          ? 'The amount ${amount.toStringAsFixed(2)} is not valid for this '
              'transaction. Amount must be greater than zero.'
          : 'The transaction amount is not valid. '
              'Amount must be greater than zero.',
      violatedRule: 'INVALID_AMOUNT',
      data: data,
      stackTrace: stackTrace,
    );
  }

  factory InvalidTransactionException.accountTypeMismatch({
    String? message,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return InvalidTransactionException(
      message: message ??
          'The selected transaction type is not supported for this account type.',
      violatedRule: 'ACCOUNT_TYPE_MISMATCH',
      data: data,
      stackTrace: stackTrace,
    );
  }


  @override
  String toString() {
    final buffer = StringBuffer('InvalidTransactionException: $message');
    if (violatedRule != null) {
      buffer.write(' [Rule: $violatedRule]');
    }
    if (data != null) {
      buffer.write('\nAdditional Data: $data');
    }
    return buffer.toString();
  }
}