import 'package:equatable/equatable.dart';

/// Data Transfer Object for login requests.
///
/// This model represents the request body for user authentication.
class LoginRequestDto extends Equatable {
  /// Username for authentication
  final String username;

  /// Password for authentication
  final String password;

  /// Creates a login request DTO.
  ///
  /// [username] - The user's username
  /// [password] - The user's password
  const LoginRequestDto({
    required this.username,
    required this.password,
  });

  /// Creates a [LoginRequestDto] from a JSON map.
  ///
  /// [json] - The JSON map containing the login credentials
  factory LoginRequestDto.fromJson(Map<String, dynamic> json) {
    return LoginRequestDto(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  /// Converts this [LoginRequestDto] to a JSON map.
  ///
  /// Returns a map that can be serialized to JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  /// Creates a copy of this [LoginRequestDto] with optional field updates.
  ///
  /// [username] - New username (optional)
  /// [password] - New password (optional)
  LoginRequestDto copyWith({
    String? username,
    String? password,
  }) {
    return LoginRequestDto(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    return 'LoginRequestDto(username: $username, password: [HIDDEN])';
  }

  @override
  List<Object?> get props => [username, password];

  /// Validates the login request fields.
  ///
  /// Returns a map of field names to error messages, or an empty map if valid.
  Map<String, String> validate() {
    final errors = <String, String>{};

    if (username.isEmpty) {
      errors['username'] = 'Username is required';
    } else if (username.length < 4) {
      errors['username'] = 'Username must be at least 4 characters';
    } else if (username.length > 50) {
      errors['username'] = 'Username must not exceed 50 characters';
    }

    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }

    return errors;
  }

  /// Checks if the login request is valid.
  bool get isValid => validate().isEmpty;
}
