import 'transaction_dto.dart';

/// Data Transfer Object for account statements
/// 
/// Represents a complete account statement for a specified date range,
/// including opening balance, closing balance, and all transactions.
class AccountStatementDTO {
  /// Account number for which this statement is generated
  final String accountNumber;
  
  /// Start date of the statement period
  final DateTime fromDate;
  
  /// End date of the statement period
  final DateTime toDate;
  
  /// Opening balance at the start of the period
  final double openingBalance;
  
  /// Closing balance at the end of the period
  final double closingBalance;
  
  /// List of transactions during the period
  final List<TransactionDTO> transactions;
  
  /// Account holder name
  final String? accountHolderName;
  
  /// Account type
  final String? accountType;
  
  /// Branch information
  final String? branchName;
  
  /// Statement generation date
  final DateTime? generatedDate;

  const AccountStatementDTO({
    required this.accountNumber,
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.closingBalance,
    required this.transactions,
    this.accountHolderName,
    this.accountType,
    this.branchName,
    this.generatedDate,
  });

  /// Create AccountStatementDTO from JSON map
  factory AccountStatementDTO.fromJson(Map<String, dynamic> json) {
    return AccountStatementDTO(
      accountNumber: json['accountNumber'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      closingBalance: (json['closingBalance'] ?? 0).toDouble(),
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => TransactionDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      accountHolderName: json['accountHolderName'] as String?,
      accountType: json['accountType'] as String?,
      branchName: json['branchName'] as String?,
      generatedDate: json['generatedDate'] != null
          ? DateTime.parse(json['generatedDate'] as String)
          : null,
    );
  }

  /// Convert AccountStatementDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      if (accountHolderName != null) 'accountHolderName': accountHolderName,
      if (accountType != null) 'accountType': accountType,
      if (branchName != null) 'branchName': branchName,
      if (generatedDate != null) 'generatedDate': generatedDate!.toIso8601String(),
    };
  }

  /// Calculate total credits (money in) during the period
  double get totalCredits {
    return transactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate total debits (money out) during the period
  double get totalDebits {
    return transactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get number of credit transactions
  int get creditTransactionCount {
    return transactions.where((t) => t.isCredit).length;
  }

  /// Get number of debit transactions
  int get debitTransactionCount {
    return transactions.where((t) => t.isDebit).length;
  }

  /// Calculate net change during the period
  double get netChange {
    return closingBalance - openingBalance;
  }

  /// Get transactions sorted by date (newest first)
  List<TransactionDTO> get sortedTransactions {
    final sorted = List<TransactionDTO>.from(transactions);
    sorted.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return sorted;
  }

  /// Filter transactions by type
  List<TransactionDTO> getTransactionsByType(String type) {
    return transactions
        .where((t) => t.transactionType.toUpperCase() == type.toUpperCase())
        .toList();
  }

  /// Get transactions for a specific date
  List<TransactionDTO> getTransactionsByDate(DateTime date) {
    return transactions.where((t) {
      return t.transactionDate.year == date.year &&
          t.transactionDate.month == date.month &&
          t.transactionDate.day == date.day;
    }).toList();
  }

  /// Create a copy with modified fields
  AccountStatementDTO copyWith({
    String? accountNumber,
    DateTime? fromDate,
    DateTime? toDate,
    double? openingBalance,
    double? closingBalance,
    List<TransactionDTO>? transactions,
    String? accountHolderName,
    String? accountType,
    String? branchName,
    DateTime? generatedDate,
  }) {
    return AccountStatementDTO(
      accountNumber: accountNumber ?? this.accountNumber,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      transactions: transactions ?? this.transactions,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountType: accountType ?? this.accountType,
      branchName: branchName ?? this.branchName,
      generatedDate: generatedDate ?? this.generatedDate,
    );
  }

  @override
  String toString() {
    return 'AccountStatementDTO(account: $accountNumber, period: ${fromDate.toIso8601String()} to ${toDate.toIso8601String()}, transactions: ${transactions.length})';
  }
}