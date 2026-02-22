import 'package:equatable/equatable.dart';
import 'user_role.dart';

/// Domain entity representing a user in the banking system
/// This is a pure domain model without any data layer concerns
class UserEntity extends Equatable {
  /// Unique identifier for the user
  final int id;

  /// Username used for authentication
  final String username;

  /// User's email address
  final String email;

  /// User's role in the system
  final UserRole role;

  /// User's full name
  final String fullName;

  /// Optional customer ID if the user is a customer
  /// This links the user account to customer-specific data
  final String? customerId;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.fullName,
    this.customerId,
  });

  /// Creates a copy of this user with the given fields replaced with new values
  UserEntity copyWith({
    int? id,
    String? username,
    String? email,
    UserRole? role,
    String? fullName,
    String? customerId,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      customerId: customerId ?? this.customerId,
    );
  }

  /// Checks if this user is a customer
  bool get isCustomer => role == UserRole.customer;

  /// Checks if this user has administrative privileges
  bool get isAdmin => role.isAdmin;

  /// Checks if this user is a staff member
  bool get isStaff => role.isStaff;

  /// Checks if this user has a linked customer account
  bool get hasCustomerAccount => customerId != null;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        role,
        fullName,
        customerId,
      ];

  @override
  String toString() {
    return 'UserEntity{'
        'id: $id, '
        'username: $username, '
        'email: $email, '
        'role: ${role.toApiString()}, '
        'fullName: $fullName, '
        'customerId: $customerId'
        '}';
  }
}
