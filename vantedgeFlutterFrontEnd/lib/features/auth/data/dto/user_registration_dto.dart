class UserRegistrationDTO {
  final String username;
  final String password;
  final String email;
  final String role; // Must be 'CUSTOMER' or 'EMPLOYEE'
  final String? branchCode; // Required for EMPLOYEE role

  const UserRegistrationDTO({
    required this.username,
    required this.password,
    required this.email,
    required this.role,
    this.branchCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'role': role,
      if (branchCode != null && branchCode!.isNotEmpty) 'branchCode': branchCode,
    };
  }

  factory UserRegistrationDTO.fromJson(Map<String, dynamic> json) {
    return UserRegistrationDTO(
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      branchCode: json['branchCode'] as String?,
    );
  }

  // Helper factory for employee registration
  factory UserRegistrationDTO.employee({
    required String username,
    required String password,
    required String email,
    String? branchCode,
  }) {
    return UserRegistrationDTO(
      username: username,
      password: password,
      email: email,
      role: 'EMPLOYEE',
      branchCode: branchCode,
    );
  }



}