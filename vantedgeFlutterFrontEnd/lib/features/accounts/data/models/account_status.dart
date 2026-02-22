/// Enumeration of account statuses in the banking system
/// 
/// - [active]: Account is active and operational
/// - [inactive]: Account is temporarily inactive
/// - [dormant]: Account has been inactive for an extended period
/// - [blocked]: Account has been blocked due to security or compliance issues
enum AccountStatus {
  /// Account is active and operational
  active('ACTIVE'),
  
  /// Account is temporarily inactive
  inactive('INACTIVE'),
  
  /// Account has been inactive for an extended period
  dormant('DORMANT'),
  
  /// Account has been blocked due to security or compliance issues
  blocked('BLOCKED');

  const AccountStatus(this.value);
  
  /// The string value used in API communication
  final String value;

  /// Create AccountStatus from string value
  static AccountStatus fromValue(String value) {
    return AccountStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => AccountStatus.inactive,
    );
  }

  /// Convert to display-friendly string
  String get displayName {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.inactive:
        return 'Inactive';
      case AccountStatus.dormant:
        return 'Dormant';
      case AccountStatus.blocked:
        return 'Blocked';
    }
  }

  /// Check if account can perform transactions
  bool get canTransact {
    return this == AccountStatus.active;
  }

  /// Get status color for UI display
  /// Returns color value as hex string
  String get statusColor {
    switch (this) {
      case AccountStatus.active:
        return '#4CAF50'; // Green
      case AccountStatus.inactive:
        return '#FF9800'; // Orange
      case AccountStatus.dormant:
        return '#9E9E9E'; // Grey
      case AccountStatus.blocked:
        return '#F44336'; // Red
    }
  }
}