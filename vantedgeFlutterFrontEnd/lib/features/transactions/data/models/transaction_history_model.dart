
import 'transaction_enums.dart';

class TransactionHistoryModel {
  final String transactionId;
  final String referenceNumber;

  final String accountNumber;

  final String? otherAccountNumber;

  final String? branchCode;
  final String? branchName;

  final String? otherBranchCode;
  final String? otherBranchName;

  final String transactionType;

  final TransferMode transferMode;
  final TransactionStatus status;

  final double amount;

  final double? balanceAfter;

  final String? description;

  final DateTime? timestamp;

  const TransactionHistoryModel({
    required this.transactionId,
    required this.referenceNumber,
    required this.accountNumber,
    this.otherAccountNumber,
    this.branchCode,
    this.branchName,
    this.otherBranchCode,
    this.otherBranchName,
    required this.transactionType,
    required this.amount,
    required this.transferMode,
    required this.status,
    this.description,
    this.timestamp,
    this.balanceAfter,
  });


  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryModel(
      transactionId: json['transactionId'] as String,
      referenceNumber: json['referenceNumber'] as String,
      accountNumber: json['accountNumber'] as String,
      otherAccountNumber: json['otherAccountNumber'] as String?,
      branchCode: json['branchCode'] as String?,
      branchName: json['branchName'] as String?,
      otherBranchCode: json['otherBranchCode'] as String?,
      otherBranchName: json['otherBranchName'] as String?,
      transactionType: (json['transactionType'] as String? ?? 'DEBIT').toUpperCase(),
      amount: (json['amount'] as num).toDouble(),
      transferMode: TransferMode.fromString(
        json['transferMode'] as String? ?? 'NEFT',
      ),
      status: TransactionStatus.fromString(
        json['status'] as String? ?? 'COMPLETED',
      ),
      description: json['description'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'referenceNumber': referenceNumber,
      'accountNumber': accountNumber,
      if (otherAccountNumber != null) 'otherAccountNumber': otherAccountNumber,
      if (branchCode != null) 'branchCode': branchCode,
      if (branchName != null) 'branchName': branchName,
      if (otherBranchCode != null) 'otherBranchCode': otherBranchCode,
      if (otherBranchName != null) 'otherBranchName': otherBranchName,
      'transactionType': transactionType,
      'amount': amount,
      'transferMode': transferMode.value,
      'status': status.value,
      if (description != null) 'description': description,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (balanceAfter != null) 'balanceAfter': balanceAfter,
    };
  }


  bool get isCredit => transactionType.toUpperCase() == 'CREDIT';

  bool get isDebit => transactionType.toUpperCase() == 'DEBIT';


  TransactionHistoryModel copyWith({
    String? transactionId,
    String? referenceNumber,
    String? accountNumber,
    String? otherAccountNumber,
    String? branchCode,
    String? branchName,
    String? otherBranchCode,
    String? otherBranchName,
    String? transactionType,
    double? amount,
    TransferMode? transferMode,
    TransactionStatus? status,
    String? description,
    DateTime? timestamp,
    double? balanceAfter,
  }) {
    return TransactionHistoryModel(
      transactionId: transactionId ?? this.transactionId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      otherAccountNumber: otherAccountNumber ?? this.otherAccountNumber,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      otherBranchCode: otherBranchCode ?? this.otherBranchCode,
      otherBranchName: otherBranchName ?? this.otherBranchName,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      transferMode: transferMode ?? this.transferMode,
      status: status ?? this.status,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      balanceAfter: balanceAfter ?? this.balanceAfter,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionHistoryModel &&
        other.transactionId == transactionId &&
        other.accountNumber == accountNumber;
  }

  @override
  int get hashCode => Object.hash(transactionId, accountNumber);

  @override
  String toString() =>
      'TransactionHistoryModel(id: $transactionId, account: $accountNumber, '
      'type: $transactionType, amount: $amount, status: ${status.value})';
}