import 'account_type.dart';
import 'account_status.dart';

/// Data Transfer Object for account list items
/// 
/// Represents a lightweight account summary used in account listings.
/// Contains essential information for displaying accounts in a list view.
class AccountListItemDTO {
  /// Unique account number
  final String accountNumber;
  
  /// Type of account (SAVINGS, CURRENT, SALARY, FD)
  final AccountType accountType;
  
  /// Display name for the account
  final String accountName;
  
  /// Current balance in the account
  final double currentBalance;
  
  /// Available balance for withdrawal/transfer
  final double availableBalance;
  
  /// Current status of the account
  final AccountStatus status;
  
  /// Name of the branch managing this account
  final String branchName;
  
  /// Branch code
  final String branchCode;

  const AccountListItemDTO({
    required this.accountNumber,
    required this.accountType,
    required this.accountName,
    required this.currentBalance,
    required this.availableBalance,
    required this.status,
    required this.branchName,
    required this.branchCode,
  });

  /// Create AccountListItemDTO from JSON map
  factory AccountListItemDTO.fromJson(Map<String, dynamic> json) {
    return AccountListItemDTO(
      accountNumber: json['accountNumber'] as String,
      accountType: AccountType.fromValue(json['accountType'] as String),
      accountName: json['accountName'] as String? ?? '',
      currentBalance: (json['currentBalance'] ?? json['balance'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? json['balance'] ?? 0).toDouble(),
      status: AccountStatus.fromValue(json['status'] as String? ?? 'INACTIVE'),
      branchName: json['branchName'] as String? ?? '',
      branchCode: json['branchCode'] as String? ?? '',
    );
  }

  /// Convert AccountListItemDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'accountType': accountType.value,
      'accountName': accountName,
      'currentBalance': currentBalance,
      'availableBalance': availableBalance,
      'status': status.value,
      'branchName': branchName,
      'branchCode': branchCode,
    };
  }

  /// Create a copy with modified fields
  AccountListItemDTO copyWith({
    String? accountNumber,
    AccountType? accountType,
    String? accountName,
    double? currentBalance,
    double? availableBalance,
    AccountStatus? status,
    String? branchName,
    String? branchCode,
  }) {
    return AccountListItemDTO(
      accountNumber: accountNumber ?? this.accountNumber,
      accountType: accountType ?? this.accountType,
      accountName: accountName ?? this.accountName,
      currentBalance: currentBalance ?? this.currentBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      status: status ?? this.status,
      branchName: branchName ?? this.branchName,
      branchCode: branchCode ?? this.branchCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountListItemDTO && other.accountNumber == accountNumber;
  }

  @override
  int get hashCode => accountNumber.hashCode;

  @override
  String toString() {
    return 'AccountListItemDTO(accountNumber: $accountNumber, accountType: ${accountType.value}, balance: $currentBalance)';
  }
}