
import 'transaction_enums.dart';

class DepositRequest {
  final String accountNumber;
  final double amount;

  final TransferMode depositMode;

  final String? description;
  final String? remarks;

  final String? chequeNumber;

  final String? bankName;

  const DepositRequest({
    required this.accountNumber,
    required this.amount,
    required this.depositMode,
    this.description,
    this.remarks,
    this.chequeNumber,
    this.bankName,
  });


  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'amount': amount,
      'depositMode': depositMode.value,
      if (description != null) 'description': description,
      if (remarks != null) 'remarks': remarks,
      if (chequeNumber != null) 'chequeNumber': chequeNumber,
      if (bankName != null) 'bankName': bankName,
    };
  }


  factory DepositRequest.fromJson(Map<String, dynamic> json) {
    return DepositRequest(
      accountNumber: json['accountNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      depositMode: TransferMode.fromString(
        json['depositMode'] as String? ?? 'CASH',
      ),
      description: json['description'] as String?,
      remarks: json['remarks'] as String?,
      chequeNumber: json['chequeNumber'] as String?,
      bankName: json['bankName'] as String?,
    );
  }


  DepositRequest copyWith({
    String? accountNumber,
    double? amount,
    TransferMode? depositMode,
    String? description,
    String? remarks,
    String? chequeNumber,
    String? bankName,
  }) {
    return DepositRequest(
      accountNumber: accountNumber ?? this.accountNumber,
      amount: amount ?? this.amount,
      depositMode: depositMode ?? this.depositMode,
      description: description ?? this.description,
      remarks: remarks ?? this.remarks,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      bankName: bankName ?? this.bankName,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DepositRequest &&
        other.accountNumber == accountNumber &&
        other.amount == amount &&
        other.depositMode == depositMode;
  }

  @override
  int get hashCode => Object.hash(accountNumber, amount, depositMode);

  @override
  String toString() =>
      'DepositRequest(account: $accountNumber, amount: $amount, '
      'mode: ${depositMode.value})';
}