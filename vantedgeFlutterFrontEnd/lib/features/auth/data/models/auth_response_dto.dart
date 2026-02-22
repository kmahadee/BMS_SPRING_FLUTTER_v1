import 'package:equatable/equatable.dart';

/// Data Transfer Object for authentication responses.
///
/// This model represents the response received after successful authentication.
class AuthResponseDto extends Equatable {
  /// JWT access token for API authentication
  final String token;

  /// User's username
  final String username;

  /// User's email address
  final String email;

  /// User's role (e.g., CUSTOMER, ADMIN, EMPLOYEE, etc.)
  final String role;

  /// Customer ID (only present for customer users)
  final String? customerId;

  /// User's full name
  final String fullName;

  /// User's unique identifier
  final int id;

  /// Creates an auth response DTO.
  const AuthResponseDto({
    required this.token,
    required this.username,
    required this.email,
    required this.role,
    this.customerId,
    required this.fullName,
    required this.id,
  });

  /// Creates an [AuthResponseDto] from a JSON map.
  ///
  /// [json] - The JSON map containing the authentication response data
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      customerId: json['customerId'] as String?,
      fullName: json['fullName'] as String,
      id: json['id'] as int,
    );
  }

  /// Converts this [AuthResponseDto] to a JSON map.
  ///
  /// Returns a map that can be serialized to JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'username': username,
      'email': email,
      'role': role,
      if (customerId != null) 'customerId': customerId,
      'fullName': fullName,
      'id': id,
    };
  }

  /// Creates a copy of this [AuthResponseDto] with optional field updates.
  AuthResponseDto copyWith({
    String? token,
    String? username,
    String? email,
    String? role,
    String? customerId,
    String? fullName,
    int? id,
  }) {
    return AuthResponseDto(
      token: token ?? this.token,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      customerId: customerId ?? this.customerId,
      fullName: fullName ?? this.fullName,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return 'AuthResponseDto('
        'id: $id, '
        'username: $username, '
        'email: $email, '
        'role: $role, '
        'customerId: $customerId, '
        'fullName: $fullName, '
        'token: [HIDDEN])';
  }

  @override
  List<Object?> get props => [
        token,
        username,
        email,
        role,
        customerId,
        fullName,
        id,
      ];

  /// Checks if the user is a customer.
  bool get isCustomer => role == 'CUSTOMER';

  /// Checks if the user is an admin.
  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';

  /// Checks if the user is a super admin.
  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  /// Checks if the user is an employee.
  bool get isEmployee => role == 'EMPLOYEE';

  /// Checks if the user is a branch manager.
  bool get isBranchManager => role == 'BRANCH_MANAGER';

  /// Checks if the user is a loan officer.
  bool get isLoanOfficer => role == 'LOAN_OFFICER';

  /// Checks if the user is a card officer.
  bool get isCardOfficer => role == 'CARD_OFFICER';

  /// Checks if the user has staff privileges (any role except CUSTOMER).
  bool get isStaff =>
      !isCustomer && (isAdmin || isEmployee || isBranchManager || isLoanOfficer || isCardOfficer);

  /// Gets a display-friendly version of the role.
  String get roleDisplay {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'ADMIN':
        return 'Admin';
      case 'CUSTOMER':
        return 'Customer';
      case 'EMPLOYEE':
        return 'Employee';
      case 'BRANCH_MANAGER':
        return 'Branch Manager';
      case 'LOAN_OFFICER':
        return 'Loan Officer';
      case 'CARD_OFFICER':
        return 'Card Officer';
      default:
        return role;
    }
  }

  /// Gets the user's initials from the full name.
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Gets the first name from the full name.
  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Gets the last name from the full name.
  String get lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }
}
