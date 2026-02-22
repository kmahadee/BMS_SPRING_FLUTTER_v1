
import 'transaction_enums.dart';

class TransactionModel {
  final String transactionId;
  final String referenceNumber;

  final String? fromAccountNumber;
  final String? toAccountNumber;
  final String? fromBranchCode;
  final String? fromBranchName;
  final String? toBranchCode;
  final String? toBranchName;

  final double amount;
  final String? currency;
  final double? transferFee;
  final double? serviceTax;
  final double? totalAmount;

  final TransferMode transferMode;
  final TransactionType transactionType;
  final TransactionStatus status;

  final String? description;
  final String? remarks;

  final DateTime? timestamp;
  final DateTime? completedAt;

  final String? receiptNumber;
  final double? balanceBefore;
  final double? balanceAfter;

  final String? beneficiaryName;
  final String? beneficiaryBank;

  final bool fraudCheckPassed;
  final bool requiresApproval;

  const TransactionModel({
    required this.transactionId,
    required this.referenceNumber,
    this.fromAccountNumber,
    this.toAccountNumber,
    this.fromBranchCode,
    this.fromBranchName,
    this.toBranchCode,
    this.toBranchName,
    required this.amount,
    this.currency,
    this.transferFee,
    this.serviceTax,
    this.totalAmount,
    required this.transferMode,
    required this.transactionType,
    required this.status,
    this.description,
    this.remarks,
    this.timestamp,
    this.completedAt,
    this.receiptNumber,
    this.balanceBefore,
    this.balanceAfter,
    this.beneficiaryName,
    this.beneficiaryBank,
    this.fraudCheckPassed = true,
    this.requiresApproval = false,
  });


  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'] as String,
      referenceNumber: json['referenceNumber'] as String,
      fromAccountNumber: json['fromAccountNumber'] as String?,
      toAccountNumber: json['toAccountNumber'] as String?,
      fromBranchCode: json['fromBranchCode'] as String?,
      fromBranchName: json['fromBranchName'] as String?,
      toBranchCode: json['toBranchCode'] as String?,
      toBranchName: json['toBranchName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String?,
      transferFee: (json['transferFee'] as num?)?.toDouble(),
      serviceTax: (json['serviceTax'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      transferMode: TransferMode.fromString(
        json['transferMode'] as String? ?? 'NEFT',
      ),
      transactionType: TransactionType.fromString(
        json['transactionType'] as String? ?? 'TRANSFER',
      ),
      status: TransactionStatus.fromString(
        json['status'] as String? ?? 'PENDING',
      ),
      description: json['description'] as String?,
      remarks: json['remarks'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      receiptNumber: json['receiptNumber'] as String?,
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble(),
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      beneficiaryName: json['beneficiaryName'] as String?,
      beneficiaryBank: json['beneficiaryBank'] as String?,
      fraudCheckPassed: json['fraudCheckPassed'] as bool? ?? true,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'referenceNumber': referenceNumber,
      if (fromAccountNumber != null) 'fromAccountNumber': fromAccountNumber,
      if (toAccountNumber != null) 'toAccountNumber': toAccountNumber,
      if (fromBranchCode != null) 'fromBranchCode': fromBranchCode,
      if (fromBranchName != null) 'fromBranchName': fromBranchName,
      if (toBranchCode != null) 'toBranchCode': toBranchCode,
      if (toBranchName != null) 'toBranchName': toBranchName,
      'amount': amount,
      if (currency != null) 'currency': currency,
      if (transferFee != null) 'transferFee': transferFee,
      if (serviceTax != null) 'serviceTax': serviceTax,
      if (totalAmount != null) 'totalAmount': totalAmount,
      'transferMode': transferMode.value,
      'transactionType': transactionType.value,
      'status': status.value,
      if (description != null) 'description': description,
      if (remarks != null) 'remarks': remarks,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
      if (balanceBefore != null) 'balanceBefore': balanceBefore,
      if (balanceAfter != null) 'balanceAfter': balanceAfter,
      if (beneficiaryName != null) 'beneficiaryName': beneficiaryName,
      if (beneficiaryBank != null) 'beneficiaryBank': beneficiaryBank,
      'fraudCheckPassed': fraudCheckPassed,
      'requiresApproval': requiresApproval,
    };
  }


  bool get isTerminal => status.isTerminal;

  bool get isSuccessful => status.isSuccessful;

  double get effectiveTotal =>
      totalAmount ?? (amount + (transferFee ?? 0.0) + (serviceTax ?? 0.0));


  TransactionModel copyWith({
    String? transactionId,
    String? referenceNumber,
    String? fromAccountNumber,
    String? toAccountNumber,
    String? fromBranchCode,
    String? fromBranchName,
    String? toBranchCode,
    String? toBranchName,
    double? amount,
    String? currency,
    double? transferFee,
    double? serviceTax,
    double? totalAmount,
    TransferMode? transferMode,
    TransactionType? transactionType,
    TransactionStatus? status,
    String? description,
    String? remarks,
    DateTime? timestamp,
    DateTime? completedAt,
    String? receiptNumber,
    double? balanceBefore,
    double? balanceAfter,
    String? beneficiaryName,
    String? beneficiaryBank,
    bool? fraudCheckPassed,
    bool? requiresApproval,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      fromAccountNumber: fromAccountNumber ?? this.fromAccountNumber,
      toAccountNumber: toAccountNumber ?? this.toAccountNumber,
      fromBranchCode: fromBranchCode ?? this.fromBranchCode,
      fromBranchName: fromBranchName ?? this.fromBranchName,
      toBranchCode: toBranchCode ?? this.toBranchCode,
      toBranchName: toBranchName ?? this.toBranchName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transferFee: transferFee ?? this.transferFee,
      serviceTax: serviceTax ?? this.serviceTax,
      totalAmount: totalAmount ?? this.totalAmount,
      transferMode: transferMode ?? this.transferMode,
      transactionType: transactionType ?? this.transactionType,
      status: status ?? this.status,
      description: description ?? this.description,
      remarks: remarks ?? this.remarks,
      timestamp: timestamp ?? this.timestamp,
      completedAt: completedAt ?? this.completedAt,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      beneficiaryBank: beneficiaryBank ?? this.beneficiaryBank,
      fraudCheckPassed: fraudCheckPassed ?? this.fraudCheckPassed,
      requiresApproval: requiresApproval ?? this.requiresApproval,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.transactionId == transactionId &&
        other.referenceNumber == referenceNumber;
  }

  @override
  int get hashCode => Object.hash(transactionId, referenceNumber);

  @override
  String toString() =>
      'TransactionModel(id: $transactionId, ref: $referenceNumber, '
      'amount: $amount, status: ${status.value})';
}