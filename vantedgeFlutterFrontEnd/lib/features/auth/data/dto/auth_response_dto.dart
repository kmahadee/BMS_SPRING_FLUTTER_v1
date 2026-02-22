import 'package:vantedge/features/auth/domain/entities/user_entity.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';

class AuthResponseDTO {
  final String accessToken;
  final String? refreshToken;  // Made nullable since backend doesn't provide it
  final int userId;
  final String username;
  final String email;
  final String role;
  final String? customerId;
  final String? fullName;  // Added since backend provides it

  const AuthResponseDTO({
    required this.accessToken,
    this.refreshToken,  // Now nullable
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.customerId,
    this.fullName,
  });

  factory AuthResponseDTO.fromJson(Map<String, dynamic> json) {
    try {
      return AuthResponseDTO(
        // Backend sends "token" not "accessToken"
        accessToken: json['token'] as String,
        
        // Backend doesn't send refreshToken, so it's null
        refreshToken: json['refreshToken'] as String?,
        
        // Backend sends "id" not "userId"
        userId: json['id'] as int,
        
        username: json['username'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        customerId: json['customerId'] as String?,
        fullName: json['fullName'] as String?,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse AuthResponseDTO: $e\nJSON: $json',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'token': accessToken,  // Match backend field name
      'refreshToken': refreshToken,
      'id': userId,  // Match backend field name
      'username': username,
      'email': email,
      'role': role,
      'customerId': customerId,
      'fullName': fullName,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: userId,
      username: username,
      email: email,
      role: UserRole.fromString(role),
      fullName: fullName ?? username,  // Use fullName if available, otherwise username
      customerId: customerId,
    );
  }
}