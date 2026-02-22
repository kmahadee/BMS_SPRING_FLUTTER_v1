import 'package:equatable/equatable.dart';

/// Data Transfer Object for customer registration requests.
///
/// This model represents the request body for registering a new customer account.
class CustomerRegistrationDto extends Equatable {
  /// Customer's first name (2-50 characters)
  final String firstName;

  /// Customer's last name (2-50 characters)
  final String lastName;

  /// Customer's email address (must be valid email format)
  final String email;

  /// Customer's phone number (E.164 format: ^\+?[1-9]\d{1,14}$)
  final String phone;

  /// Customer's date of birth
  final DateTime dateOfBirth;

  /// Customer's street address (max 255 characters)
  final String address;

  /// Customer's city (max 50 characters)
  final String city;

  /// Customer's state/province (max 50 characters)
  final String state;

  /// Customer's zip/postal code (3-10 digits: ^\d{3,10}$)
  final String zipCode;

  /// Optional profile image (base64 encoded or URL)
  final String? image;

  /// Username for account login (4-50 characters)
  final String username;

  /// Password for account login (minimum 6 characters)
  final String password;

  /// Creates a customer registration DTO.
  const CustomerRegistrationDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.image,
    required this.username,
    required this.password,
  });

  /// Creates a [CustomerRegistrationDto] from a JSON map.
  ///
  /// [json] - The JSON map containing the registration data
  factory CustomerRegistrationDto.fromJson(Map<String, dynamic> json) {
    return CustomerRegistrationDto(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      image: json['image'] as String?,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  /// Converts this [CustomerRegistrationDto] to a JSON map.
  ///
  /// Returns a map that can be serialized to JSON.
  /// Date of birth is formatted as YYYY-MM-DD.
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': _formatDate(dateOfBirth),
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      if (image != null) 'image': image,
      'username': username,
      'password': password,
    };
  }

  /// Formats a [DateTime] to YYYY-MM-DD format.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Creates a copy of this [CustomerRegistrationDto] with optional field updates.
  CustomerRegistrationDto copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? image,
    String? username,
    String? password,
  }) {
    return CustomerRegistrationDto(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      image: image ?? this.image,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    return 'CustomerRegistrationDto('
        'firstName: $firstName, '
        'lastName: $lastName, '
        'email: $email, '
        'phone: $phone, '
        'dateOfBirth: ${_formatDate(dateOfBirth)}, '
        'address: $address, '
        'city: $city, '
        'state: $state, '
        'zipCode: $zipCode, '
        'image: ${image != null ? '[PROVIDED]' : 'null'}, '
        'username: $username, '
        'password: [HIDDEN])';
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        phone,
        dateOfBirth,
        address,
        city,
        state,
        zipCode,
        image,
        username,
        password,
      ];

  /// Gets the customer's full name.
  String get fullName => '$firstName $lastName';

  /// Regular expression patterns for validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final RegExp _zipRegex = RegExp(r'^\d{3,10}$');
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9._]{4,50}$');

  /// Validates the registration data.
  ///
  /// Returns a map of field names to error messages, or an empty map if valid.
  Map<String, String> validate() {
    final errors = <String, String>{};

    // First name validation
    if (firstName.isEmpty) {
      errors['firstName'] = 'First name is required';
    } else if (firstName.length < 2) {
      errors['firstName'] = 'First name must be at least 2 characters';
    } else if (firstName.length > 50) {
      errors['firstName'] = 'First name must not exceed 50 characters';
    }

    // Last name validation
    if (lastName.isEmpty) {
      errors['lastName'] = 'Last name is required';
    } else if (lastName.length < 2) {
      errors['lastName'] = 'Last name must be at least 2 characters';
    } else if (lastName.length > 50) {
      errors['lastName'] = 'Last name must not exceed 50 characters';
    }

    // Email validation
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!_emailRegex.hasMatch(email)) {
      errors['email'] = 'Invalid email format';
    }

    // Phone validation
    if (phone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!_phoneRegex.hasMatch(phone)) {
      errors['phone'] = 'Invalid phone number format (use E.164 format)';
    }

    // Date of birth validation
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    final hasHadBirthdayThisYear = now.month > dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    final actualAge = hasHadBirthdayThisYear ? age : age - 1;

    if (dateOfBirth.isAfter(now)) {
      errors['dateOfBirth'] = 'Date of birth cannot be in the future';
    } else if (actualAge < 18) {
      errors['dateOfBirth'] = 'You must be at least 18 years old';
    } else if (actualAge > 120) {
      errors['dateOfBirth'] = 'Invalid date of birth';
    }

    // Address validation
    if (address.isEmpty) {
      errors['address'] = 'Address is required';
    } else if (address.length > 255) {
      errors['address'] = 'Address must not exceed 255 characters';
    }

    // City validation
    if (city.isEmpty) {
      errors['city'] = 'City is required';
    } else if (city.length > 50) {
      errors['city'] = 'City must not exceed 50 characters';
    }

    // State validation
    if (state.isEmpty) {
      errors['state'] = 'State is required';
    } else if (state.length > 50) {
      errors['state'] = 'State must not exceed 50 characters';
    }

    // Zip code validation
    if (zipCode.isEmpty) {
      errors['zipCode'] = 'Zip code is required';
    } else if (!_zipRegex.hasMatch(zipCode)) {
      errors['zipCode'] = 'Zip code must be 3-10 digits';
    }

    // Username validation
    if (username.isEmpty) {
      errors['username'] = 'Username is required';
    } else if (username.length < 4) {
      errors['username'] = 'Username must be at least 4 characters';
    } else if (username.length > 50) {
      errors['username'] = 'Username must not exceed 50 characters';
    } else if (!_usernameRegex.hasMatch(username)) {
      errors['username'] =
          'Username can only contain letters, numbers, dots, and underscores';
    }

    // Password validation
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }

    return errors;
  }

  /// Checks if the registration data is valid.
  bool get isValid => validate().isEmpty;

  /// Calculates the age based on date of birth.
  int get age {
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    final hasHadBirthdayThisYear = now.month > dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    return hasHadBirthdayThisYear ? age : age - 1;
  }

  /// Checks if the customer is eligible for loans (21+ years old).
  bool get isEligibleForLoan => age >= 21;
}
