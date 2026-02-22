/// Data Transfer Object for account balance information
/// 
/// Represents the current balance state of an account at a specific point in time.
class AccountBalanceDTO {
  /// Unique account number
  final String accountNumber;
  
  /// Current total balance in the account
  final double currentBalance;
  
  /// Available balance for withdrawal/transfer (may be less than current balance)
  final double availableBalance;
  
  /// Date and time when this balance was recorded
  final DateTime balanceDate;

  const AccountBalanceDTO({
    required this.accountNumber,
    required this.currentBalance,
    required this.availableBalance,
    required this.balanceDate,
  });

  /// Create AccountBalanceDTO from JSON map
  factory AccountBalanceDTO.fromJson(Map<String, dynamic> json) {
    return AccountBalanceDTO(
      accountNumber: json['accountNumber'] as String,
      currentBalance: (json['currentBalance'] ?? json['balance'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? json['currentBalance'] ?? json['balance'] ?? 0).toDouble(),
      balanceDate: json['balanceDate'] != null 
          ? DateTime.parse(json['balanceDate'] as String)
          : DateTime.now(),
    );
  }

  /// Convert AccountBalanceDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'currentBalance': currentBalance,
      'availableBalance': availableBalance,
      'balanceDate': balanceDate.toIso8601String(),
    };
  }

  /// Calculate the difference between current and available balance
  /// This represents any holds, pending transactions, or reserved amounts
  double get heldAmount {
    return currentBalance - availableBalance;
  }

  /// Check if there are any holds on the account
  bool get hasHolds {
    return heldAmount > 0;
  }

  /// Create a copy with modified fields
  AccountBalanceDTO copyWith({
    String? accountNumber,
    double? currentBalance,
    double? availableBalance,
    DateTime? balanceDate,
  }) {
    return AccountBalanceDTO(
      accountNumber: accountNumber ?? this.accountNumber,
      currentBalance: currentBalance ?? this.currentBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      balanceDate: balanceDate ?? this.balanceDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountBalanceDTO &&
        other.accountNumber == accountNumber &&
        other.balanceDate == balanceDate;
  }

  @override
  int get hashCode => Object.hash(accountNumber, balanceDate);

  @override
  String toString() {
    return 'AccountBalanceDTO(accountNumber: $accountNumber, currentBalance: $currentBalance, availableBalance: $availableBalance, date: $balanceDate)';
  }
}