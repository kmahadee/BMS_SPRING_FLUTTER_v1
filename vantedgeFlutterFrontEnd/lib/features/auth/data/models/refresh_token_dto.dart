import 'package:equatable/equatable.dart';

/// Data Transfer Object for refresh token requests.
///
/// This model represents the request body for refreshing an authentication token.
class RefreshTokenDto extends Equatable {
  /// The refresh token to use for obtaining a new access token
  final String refreshToken;

  /// Creates a refresh token DTO.
  ///
  /// [refreshToken] - The refresh token string
  const RefreshTokenDto({
    required this.refreshToken,
  });

  /// Creates a [RefreshTokenDto] from a JSON map.
  ///
  /// [json] - The JSON map containing the refresh token
  factory RefreshTokenDto.fromJson(Map<String, dynamic> json) {
    return RefreshTokenDto(
      refreshToken: json['refreshToken'] as String,
    );
  }

  /// Converts this [RefreshTokenDto] to a JSON map.
  ///
  /// Returns a map that can be serialized to JSON
  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }

  /// Creates a copy of this [RefreshTokenDto] with optional field updates.
  ///
  /// [refreshToken] - New refresh token (optional)
  RefreshTokenDto copyWith({
    String? refreshToken,
  }) {
    return RefreshTokenDto(
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  String toString() {
    return 'RefreshTokenDto(refreshToken: [HIDDEN])';
  }

  @override
  List<Object?> get props => [refreshToken];

  /// Validates the refresh token.
  ///
  /// Returns a map of field names to error messages, or an empty map if valid.
  Map<String, String> validate() {
    final errors = <String, String>{};

    if (refreshToken.isEmpty) {
      errors['refreshToken'] = 'Refresh token is required';
    } else if (refreshToken.length < 10) {
      errors['refreshToken'] = 'Invalid refresh token format';
    }

    return errors;
  }

  /// Checks if the refresh token is valid.
  bool get isValid => validate().isEmpty;
}
