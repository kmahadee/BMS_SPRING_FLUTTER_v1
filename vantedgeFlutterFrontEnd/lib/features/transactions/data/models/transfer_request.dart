
import 'transaction_enums.dart';

class TransferRequest {
  final String fromAccountNumber;
  final String toAccountNumber;
  final double amount;
  final TransferMode transferMode;

  final String? description;
  final String? remarks;

  final String? priority;

  final TransferType? transferType;

  const TransferRequest({
    required this.fromAccountNumber,
    required this.toAccountNumber,
    required this.amount,
    required this.transferMode,
    this.description,
    this.remarks,
    this.priority,
    this.transferType,
  });


  Map<String, dynamic> toJson() {
    return {
      'fromAccountNumber': fromAccountNumber,
      'toAccountNumber': toAccountNumber,
      'amount': amount,
      'transferMode': transferMode.value,
      if (description != null) 'description': description,
      if (remarks != null) 'remarks': remarks,
      if (priority != null) 'priority': priority,
      if (transferType != null) 'transferType': transferType!.value,
    };
  }


  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    return TransferRequest(
      fromAccountNumber: json['fromAccountNumber'] as String,
      toAccountNumber: json['toAccountNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      transferMode: TransferMode.fromString(
        json['transferMode'] as String? ?? 'NEFT',
      ),
      description: json['description'] as String?,
      remarks: json['remarks'] as String?,
      priority: json['priority'] as String?,
      transferType: json['transferType'] != null
          ? TransferType.fromString(json['transferType'] as String)
          : null,
    );
  }


  TransferRequest copyWith({
    String? fromAccountNumber,
    String? toAccountNumber,
    double? amount,
    TransferMode? transferMode,
    String? description,
    String? remarks,
    String? priority,
    TransferType? transferType,
  }) {
    return TransferRequest(
      fromAccountNumber: fromAccountNumber ?? this.fromAccountNumber,
      toAccountNumber: toAccountNumber ?? this.toAccountNumber,
      amount: amount ?? this.amount,
      transferMode: transferMode ?? this.transferMode,
      description: description ?? this.description,
      remarks: remarks ?? this.remarks,
      priority: priority ?? this.priority,
      transferType: transferType ?? this.transferType,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferRequest &&
        other.fromAccountNumber == fromAccountNumber &&
        other.toAccountNumber == toAccountNumber &&
        other.amount == amount &&
        other.transferMode == transferMode;
  }

  @override
  int get hashCode =>
      Object.hash(fromAccountNumber, toAccountNumber, amount, transferMode);

  @override
  String toString() =>
      'TransferRequest(from: $fromAccountNumber, to: $toAccountNumber, '
      'amount: $amount, mode: ${transferMode.value})';
}