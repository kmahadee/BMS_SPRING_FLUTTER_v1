/// Enumeration of account types supported by the banking system
/// 
/// - [savings]: Regular savings account
/// - [current]: Current/checking account for businesses
/// - [salary]: Salary account for employees
/// - [fd]: Fixed deposit account
enum AccountType {
  /// Regular savings account with interest
  savings('SAVINGS'),
  
  /// Current/checking account for businesses
  current('CURRENT'),
  
  /// Salary account for employees
  salary('SALARY'),
  
  /// Fixed deposit account
  fd('FD');

  const AccountType(this.value);
  
  /// The string value used in API communication
  final String value;

  /// Create AccountType from string value
  static AccountType fromValue(String value) {
    return AccountType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => AccountType.savings,
    );
  }

  /// Convert to display-friendly string
  String get displayName {
    switch (this) {
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.current:
        return 'Current Account';
      case AccountType.salary:
        return 'Salary Account';
      case AccountType.fd:
        return 'Fixed Deposit';
    }
  }
}