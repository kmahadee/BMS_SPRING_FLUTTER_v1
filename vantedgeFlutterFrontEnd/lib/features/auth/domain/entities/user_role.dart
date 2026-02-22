/// Enum representing different user roles in the banking system
enum UserRole {
  customer,
  employee,
  admin,
  branchManager,
  loanOfficer,
  cardOfficer,
  superAdmin;

  /// Converts a string representation to UserRole enum
  /// Throws ArgumentError if the role string is invalid
  static UserRole fromString(String role) {
    final normalizedRole = role.toLowerCase().trim();
    
    switch (normalizedRole) {
      case 'customer':
        return UserRole.customer;
      case 'employee':
        return UserRole.employee;
      case 'admin':
        return UserRole.admin;
      case 'branch_manager':
      case 'branchmanager':
        return UserRole.branchManager;
      case 'loan_officer':
      case 'loanofficer':
        return UserRole.loanOfficer;
      case 'card_officer':
      case 'cardofficer':
        return UserRole.cardOfficer;
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }

  /// Converts the UserRole enum to API string format
  /// Uses snake_case for consistency with backend API
  String toApiString() {
    switch (this) {
      case UserRole.customer:
        return 'CUSTOMER';
      case UserRole.employee:
        return 'EMPLOYEE';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.branchManager:
        return 'BRANCH_MANAGER';
      case UserRole.loanOfficer:
        return 'LOAN_OFFICER';
      case UserRole.cardOfficer:
        return 'CARD_OFFICER';
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
    }
  }

  /// Returns a human-readable display name for the role
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.employee:
        return 'Employee';
      case UserRole.admin:
        return 'Admin';
      case UserRole.branchManager:
        return 'Branch Manager';
      case UserRole.loanOfficer:
        return 'Loan Officer';
      case UserRole.cardOfficer:
        return 'Card Officer';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  /// Checks if the role has administrative privileges
  bool get isAdmin {
    return this == UserRole.admin || 
           this == UserRole.superAdmin || 
           this == UserRole.branchManager;
  }

  /// Checks if the role is a staff member
  bool get isStaff {
    return this != UserRole.customer;
  }
}
