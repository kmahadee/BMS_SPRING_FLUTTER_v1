class AccountBalanceModel {
  final String accountNumber;

  final String? customerId;

  final String accountType;

  final String? branchCode;
  final String? branchName;

  final double balance;

  final String? currency;

  final String status;

  const AccountBalanceModel({
    required this.accountNumber,
    this.customerId,
    required this.accountType,
    this.branchCode,
    this.branchName,
    required this.balance,
    this.currency,
    required this.status,
  });


  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) {
    return AccountBalanceModel(
      accountNumber: json['accountNumber'] as String,
      customerId: json['customerId'] as String?,
      accountType: json['accountType'] as String? ?? '',
      branchCode: json['branchCode'] as String?,
      branchName: json['branchName'] as String?,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String?,
      status: json['status'] as String? ?? 'unknown',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      if (customerId != null) 'customerId': customerId,
      'accountType': accountType,
      if (branchCode != null) 'branchCode': branchCode,
      if (branchName != null) 'branchName': branchName,
      'balance': balance,
      if (currency != null) 'currency': currency,
      'status': status,
    };
  }


  bool get isActive => status.toUpperCase() == 'ACTIVE';

  String get formattedBalance =>
      '${currency ?? '\$'}${balance.toStringAsFixed(2)}';


  AccountBalanceModel copyWith({
    String? accountNumber,
    String? customerId,
    String? accountType,
    String? branchCode,
    String? branchName,
    double? balance,
    String? currency,
    String? status,
  }) {
    return AccountBalanceModel(
      accountNumber: accountNumber ?? this.accountNumber,
      customerId: customerId ?? this.customerId,
      accountType: accountType ?? this.accountType,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      status: status ?? this.status,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountBalanceModel &&
        other.accountNumber == accountNumber;
  }

  @override
  int get hashCode => accountNumber.hashCode;

  @override
  String toString() =>
      'AccountBalanceModel(account: $accountNumber, balance: $balance, '
      'status: $status)';
}