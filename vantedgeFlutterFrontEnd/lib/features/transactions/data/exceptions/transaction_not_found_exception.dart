
import 'package:vantedge/core/exceptions/api_exceptions.dart';

class TransactionNotFoundException extends NotFoundException {
  final String? transactionId;

  final String? referenceNumber;

  const TransactionNotFoundException({
    super.message = 'Transaction not found.',
    this.transactionId,
    this.referenceNumber,
    super.data,
    super.stackTrace,
  });


  factory TransactionNotFoundException.forTransactionId(
    String transactionId, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return TransactionNotFoundException(
      message: customMessage ??
          'Transaction with ID "$transactionId" was not found.',
      transactionId: transactionId,
      data: data,
      stackTrace: stackTrace,
    );
  }

  factory TransactionNotFoundException.forReferenceNumber(
    String referenceNumber, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return TransactionNotFoundException(
      message: customMessage ??
          'Transaction with reference number "$referenceNumber" was not found.',
      referenceNumber: referenceNumber,
      data: data,
      stackTrace: stackTrace,
    );
  }

  factory TransactionNotFoundException.withMessage(
    String message, {
    String? transactionId,
    String? referenceNumber,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return TransactionNotFoundException(
      message: message,
      transactionId: transactionId,
      referenceNumber: referenceNumber,
      data: data,
      stackTrace: stackTrace,
    );
  }


  @override
  String toString() {
    final buffer = StringBuffer('TransactionNotFoundException: $message');
    if (transactionId != null) {
      buffer.write(' (Transaction ID: $transactionId)');
    }
    if (referenceNumber != null) {
      buffer.write(' (Reference Number: $referenceNumber)');
    }
    if (data != null) {
      buffer.write('\nAdditional Data: $data');
    }
    return buffer.toString();
  }
}