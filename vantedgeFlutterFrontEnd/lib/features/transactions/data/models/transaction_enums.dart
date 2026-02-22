
enum TransactionStatus {
  completed('COMPLETED'),
  pending('PENDING'),
  failed('FAILED'),
  cancelled('CANCELLED'),
  processing('PROCESSING');

  const TransactionStatus(this.value);

  final String value;

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (s) => s.value == value.toUpperCase(),
      orElse: () => TransactionStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.processing:
        return 'Processing';
    }
  }

  bool get isTerminal =>
      this == TransactionStatus.completed ||
      this == TransactionStatus.failed ||
      this == TransactionStatus.cancelled;

  bool get isSuccessful => this == TransactionStatus.completed;
}

enum TransferMode {
  neft('NEFT'),
  rtgs('RTGS'),
  imps('IMPS'),
  upi('UPI'),
  cash('CASH'),
  cheque('CHEQUE'),
  card('CARD');

  const TransferMode(this.value);

  final String value;

  static TransferMode fromString(String value) {
    return TransferMode.values.firstWhere(
      (m) => m.value == value.toUpperCase(),
      orElse: () => TransferMode.neft,
    );
  }

  String get displayName {
    switch (this) {
      case TransferMode.neft:
        return 'NEFT';
      case TransferMode.rtgs:
        return 'RTGS';
      case TransferMode.imps:
        return 'IMPS';
      case TransferMode.upi:
        return 'UPI';
      case TransferMode.cash:
        return 'Cash';
      case TransferMode.cheque:
        return 'Cheque';
      case TransferMode.card:
        return 'Card';
    }
  }
}

enum TransactionType {
  transfer('TRANSFER'),
  deposit('DEPOSIT'),
  withdrawal('WITHDRAWAL'),
  payment('PAYMENT'),
  refund('REFUND');

  const TransactionType(this.value);

  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.value == value.toUpperCase(),
      orElse: () => TransactionType.transfer,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.refund:
        return 'Refund';
    }
  }

  bool get isCredit =>
      this == TransactionType.deposit || this == TransactionType.refund;

  bool get isDebit =>
      this == TransactionType.withdrawal ||
      this == TransactionType.payment ||
      this == TransactionType.transfer;
}

enum TransferType {
  own('OWN'),
  other('OTHER');

  const TransferType(this.value);

  final String value;

  static TransferType fromString(String value) {
    return TransferType.values.firstWhere(
      (t) => t.value == value.toUpperCase(),
      orElse: () => TransferType.other,
    );
  }

  String get displayName {
    switch (this) {
      case TransferType.own:
        return 'Own Account';
      case TransferType.other:
        return 'Other Account';
    }
  }
}