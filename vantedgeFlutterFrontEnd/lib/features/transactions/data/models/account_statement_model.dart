import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';

class AccountStatementModel {
  final String accountNumber;
  final String? accountType;
  final String? customerName;
  final String? customerEmail;

  final String? branchCode;
  final String? branchName;
  final String? branchAddress;

  final DateTime? statementStartDate;
  final DateTime? statementEndDate;

  final double openingBalance;
  final double closingBalance;
  final double totalCredits;
  final double totalDebits;

  final int transactionCount;

  final List<TransactionHistoryModel> transactions;

  const AccountStatementModel({
    required this.accountNumber,
    this.accountType,
    this.customerName,
    this.customerEmail,
    this.branchCode,
    this.branchName,
    this.branchAddress,
    this.statementStartDate,
    this.statementEndDate,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalCredits,
    required this.totalDebits,
    required this.transactionCount,
    required this.transactions,
  });


  factory AccountStatementModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['transactions'] as List<dynamic>? ?? [];
    final transactions = rawList
        .map((item) =>
            TransactionHistoryModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return AccountStatementModel(
      accountNumber: json['accountNumber'] as String,
      accountType: json['accountType'] as String?,
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
      branchCode: json['branchCode'] as String?,
      branchName: json['branchName'] as String?,
      branchAddress: json['branchAddress'] as String?,
      statementStartDate: json['statementStartDate'] != null
          ? DateTime.tryParse(json['statementStartDate'] as String)
          : null,
      statementEndDate: json['statementEndDate'] != null
          ? DateTime.tryParse(json['statementEndDate'] as String)
          : null,
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (json['closingBalance'] as num?)?.toDouble() ?? 0.0,
      totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0.0,
      totalDebits: (json['totalDebits'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transactionCount'] as int? ?? transactions.length,
      transactions: transactions,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      if (accountType != null) 'accountType': accountType,
      if (customerName != null) 'customerName': customerName,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (branchCode != null) 'branchCode': branchCode,
      if (branchName != null) 'branchName': branchName,
      if (branchAddress != null) 'branchAddress': branchAddress,
      if (statementStartDate != null)
        'statementStartDate': statementStartDate!.toIso8601String(),
      if (statementEndDate != null)
        'statementEndDate': statementEndDate!.toIso8601String(),
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'transactionCount': transactionCount,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }


  double get netMovement => totalCredits - totalDebits;

  bool get hasTransactions => transactions.isNotEmpty;


  AccountStatementModel copyWith({
    String? accountNumber,
    String? accountType,
    String? customerName,
    String? customerEmail,
    String? branchCode,
    String? branchName,
    String? branchAddress,
    DateTime? statementStartDate,
    DateTime? statementEndDate,
    double? openingBalance,
    double? closingBalance,
    double? totalCredits,
    double? totalDebits,
    int? transactionCount,
    List<TransactionHistoryModel>? transactions,
  }) {
    return AccountStatementModel(
      accountNumber: accountNumber ?? this.accountNumber,
      accountType: accountType ?? this.accountType,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      branchAddress: branchAddress ?? this.branchAddress,
      statementStartDate: statementStartDate ?? this.statementStartDate,
      statementEndDate: statementEndDate ?? this.statementEndDate,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      totalCredits: totalCredits ?? this.totalCredits,
      totalDebits: totalDebits ?? this.totalDebits,
      transactionCount: transactionCount ?? this.transactionCount,
      transactions: transactions ?? this.transactions,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountStatementModel &&
        other.accountNumber == accountNumber &&
        other.statementStartDate == statementStartDate &&
        other.statementEndDate == statementEndDate;
  }

  @override
  int get hashCode =>
      Object.hash(accountNumber, statementStartDate, statementEndDate);

  @override
  String toString() =>
      'AccountStatementModel(account: $accountNumber, '
      'transactions: ${transactions.length}, '
      'credits: $totalCredits, debits: $totalDebits)';
}