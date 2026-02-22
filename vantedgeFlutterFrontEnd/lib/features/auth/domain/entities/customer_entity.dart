import 'package:equatable/equatable.dart';

/// Domain entity representing a customer in the banking system
/// This is a pure domain model without any data layer concerns
class CustomerEntity extends Equatable {
  /// Unique customer identifier
  final String id;

  /// Customer's first name
  final String firstName;

  /// Customer's last name
  final String lastName;

  /// Customer's email address
  final String email;

  /// Customer's phone number
  final String phone;

  /// Customer's date of birth
  final DateTime dateOfBirth;

  /// Customer's street address
  final String address;

  /// Customer's city
  final String city;

  /// Customer's state
  final String state;

  /// Customer's ZIP code
  final String zipCode;

  const CustomerEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  /// Creates a copy of this customer with the given fields replaced with new values
  CustomerEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
    );
  }

  /// Returns the customer's full name
  String get fullName => '$firstName $lastName';

  /// Returns the customer's age based on date of birth
  int get age {
    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth.year;
    
    // Adjust if birthday hasn't occurred yet this year
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      calculatedAge--;
    }
    
    return calculatedAge;
  }

  /// Returns the customer's full address as a single string
  String get fullAddress => '$address, $city, $state $zipCode';

  /// Returns initials from first and last name
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        dateOfBirth,
        address,
        city,
        state,
        zipCode,
      ];

  @override
  String toString() {
    return 'CustomerEntity{'
        'id: $id, '
        'fullName: $fullName, '
        'email: $email, '
        'phone: $phone, '
        'dateOfBirth: ${dateOfBirth.toIso8601String()}, '
        'address: $fullAddress'
        '}';
  }
}
