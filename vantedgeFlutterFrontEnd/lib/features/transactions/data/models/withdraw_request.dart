
import 'transaction_enums.dart';

class WithdrawRequest {
  final String accountNumber;
  final double amount;

  final TransferMode withdrawalMode;

  final String? description;
  final String? remarks;

  const WithdrawRequest({
    required this.accountNumber,
    required this.amount,
    required this.withdrawalMode,
    this.description,
    this.remarks,
  });


  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'amount': amount,
      'withdrawalMode': withdrawalMode.value,
      if (description != null) 'description': description,
      if (remarks != null) 'remarks': remarks,
    };
  }


  factory WithdrawRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawRequest(
      accountNumber: json['accountNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      withdrawalMode: TransferMode.fromString(
        json['withdrawalMode'] as String? ?? 'CASH',
      ),
      description: json['description'] as String?,
      remarks: json['remarks'] as String?,
    );
  }


  WithdrawRequest copyWith({
    String? accountNumber,
    double? amount,
    TransferMode? withdrawalMode,
    String? description,
    String? remarks,
  }) {
    return WithdrawRequest(
      accountNumber: accountNumber ?? this.accountNumber,
      amount: amount ?? this.amount,
      withdrawalMode: withdrawalMode ?? this.withdrawalMode,
      description: description ?? this.description,
      remarks: remarks ?? this.remarks,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WithdrawRequest &&
        other.accountNumber == accountNumber &&
        other.amount == amount &&
        other.withdrawalMode == withdrawalMode;
  }

  @override
  int get hashCode => Object.hash(accountNumber, amount, withdrawalMode);

  @override
  String toString() =>
      'WithdrawRequest(account: $accountNumber, amount: $amount, '
      'mode: ${withdrawalMode.value})';
}