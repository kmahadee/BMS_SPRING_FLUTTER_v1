/// Data Transfer Object for transaction information
/// 
/// Represents a single transaction in an account statement or transaction history.
class TransactionDTO {
  /// Unique transaction ID
  final String? id;
  
  /// Transaction reference number
  final String? transactionReference;
  
  /// Type of transaction (DEPOSIT, WITHDRAWAL, TRANSFER, etc.)
  final String transactionType;
  
  /// Transaction amount
  final double amount;
  
  /// Account number from which the transaction originated
  final String? fromAccount;
  
  /// Account number to which the transaction was sent
  final String? toAccount;
  
  /// Date and time of the transaction
  final DateTime transactionDate;
  
  /// Description or narration of the transaction
  final String? description;
  
  /// Balance after this transaction
  final double? balanceAfter;
  
  /// Transaction status (COMPLETED, PENDING, FAILED, REVERSED)
  final String? status;
  
  /// Channel through which transaction was made (ATM, ONLINE, BRANCH, etc.)
  final String? channel;

  const TransactionDTO({
    this.id,
    this.transactionReference,
    required this.transactionType,
    required this.amount,
    this.fromAccount,
    this.toAccount,
    required this.transactionDate,
    this.description,
    this.balanceAfter,
    this.status,
    this.channel,
  });

  /// Create TransactionDTO from JSON map
  factory TransactionDTO.fromJson(Map<String, dynamic> json) {
    return TransactionDTO(
      id: json['id']?.toString(),
      transactionReference: json['transactionReference'] as String?,
      transactionType: json['transactionType'] as String,
      amount: (json['amount'] ?? 0).toDouble(),
      fromAccount: json['fromAccount'] as String?,
      toAccount: json['toAccount'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      description: json['description'] as String?,
      balanceAfter: json['balanceAfter'] != null 
          ? (json['balanceAfter'] as num).toDouble() 
          : null,
      status: json['status'] as String?,
      channel: json['channel'] as String?,
    );
  }

  /// Convert TransactionDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (transactionReference != null) 'transactionReference': transactionReference,
      'transactionType': transactionType,
      'amount': amount,
      if (fromAccount != null) 'fromAccount': fromAccount,
      if (toAccount != null) 'toAccount': toAccount,
      'transactionDate': transactionDate.toIso8601String(),
      if (description != null) 'description': description,
      if (balanceAfter != null) 'balanceAfter': balanceAfter,
      if (status != null) 'status': status,
      if (channel != null) 'channel': channel,
    };
  }

  /// Check if transaction is a credit (money in)
  bool get isCredit {
    return transactionType.toUpperCase() == 'DEPOSIT' || 
           transactionType.toUpperCase() == 'CREDIT' ||
           transactionType.toUpperCase() == 'TRANSFER_IN';
  }

  /// Check if transaction is a debit (money out)
  bool get isDebit {
    return transactionType.toUpperCase() == 'WITHDRAWAL' || 
           transactionType.toUpperCase() == 'DEBIT' ||
           transactionType.toUpperCase() == 'TRANSFER' ||
           transactionType.toUpperCase() == 'TRANSFER_OUT';
  }

  /// Get display-friendly transaction type
  String get displayType {
    switch (transactionType.toUpperCase()) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'TRANSFER':
      case 'TRANSFER_OUT':
        return 'Transfer Out';
      case 'TRANSFER_IN':
        return 'Transfer In';
      case 'LOAN_DISBURSEMENT':
        return 'Loan Disbursement';
      case 'LOAN_REPAYMENT':
        return 'Loan Repayment';
      case 'INTEREST_CREDIT':
        return 'Interest Credit';
      case 'FEE_DEBIT':
        return 'Fee Debit';
      default:
        return transactionType;
    }
  }

  /// Create a copy with modified fields
  TransactionDTO copyWith({
    String? id,
    String? transactionReference,
    String? transactionType,
    double? amount,
    String? fromAccount,
    String? toAccount,
    DateTime? transactionDate,
    String? description,
    double? balanceAfter,
    String? status,
    String? channel,
  }) {
    return TransactionDTO(
      id: id ?? this.id,
      transactionReference: transactionReference ?? this.transactionReference,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      status: status ?? this.status,
      channel: channel ?? this.channel,
    );
  }

  @override
  String toString() {
    return 'TransactionDTO(ref: $transactionReference, type: $transactionType, amount: $amount, date: $transactionDate)';
  }
}