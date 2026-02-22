import 'package:vantedge/core/exceptions/api_exceptions.dart';

class InsufficientBalanceException extends BadRequestException {
  final String? accountNumber;

  final double? availableBalance;

  final double? requiredAmount;

  const InsufficientBalanceException({
    super.message = 'Insufficient balance to complete this transaction.',
    this.accountNumber,
    this.availableBalance,
    this.requiredAmount,
    super.data,
    super.stackTrace,
  });


  factory InsufficientBalanceException.forAccount(
    String accountNumber, {
    double? availableBalance,
    double? requiredAmount,
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    final available = availableBalance != null
        ? availableBalance.toStringAsFixed(2)
        : 'unknown';
    final required = requiredAmount != null
        ? requiredAmount.toStringAsFixed(2)
        : 'unknown';

    return InsufficientBalanceException(
      message: customMessage ??
          'Insufficient balance for account $accountNumber. '
              'Available: \$$available, Required: \$$required.',
      accountNumber: accountNumber,
      availableBalance: availableBalance,
      requiredAmount: requiredAmount,
      data: data,
      stackTrace: stackTrace,
    );
  }

  factory InsufficientBalanceException.fromMessage(
    String rawMessage, {
    String? accountNumber,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    double? available;
    double? required;

    final availableMatch =
        RegExp(r'Available:\s*([\d.]+)').firstMatch(rawMessage);
    final requiredMatch =
        RegExp(r'(?:Required|Requested):\s*([\d.]+)').firstMatch(rawMessage);

    if (availableMatch != null) {
      available = double.tryParse(availableMatch.group(1)!);
    }
    if (requiredMatch != null) {
      required = double.tryParse(requiredMatch.group(1)!);
    }

    return InsufficientBalanceException(
      message:
          'Insufficient balance to complete this transaction. Please check '
          'your account balance and try again.',
      accountNumber: accountNumber,
      availableBalance: available,
      requiredAmount: required,
      data: data,
      stackTrace: stackTrace,
    );
  }


  @override
  String toString() {
    final buffer = StringBuffer('InsufficientBalanceException: $message');
    if (accountNumber != null) {
      buffer.write(' (Account: $accountNumber)');
    }
    if (availableBalance != null) {
      buffer.write(' [Available: ${availableBalance!.toStringAsFixed(2)}]');
    }
    if (requiredAmount != null) {
      buffer.write(' [Required: ${requiredAmount!.toStringAsFixed(2)}]');
    }
    if (data != null) {
      buffer.write('\nAdditional Data: $data');
    }
    return buffer.toString();
  }
}