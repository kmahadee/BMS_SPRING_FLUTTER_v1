class CustomerRegistrationDTO {
  final String username;
  final String password;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String zipCode;

  const CustomerRegistrationDTO({
    required this.username,
    required this.password,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }
}