import '../../domain/entities/customer_entity.dart';

class CustomerResponseDTO {
  final String id;
  final String customerId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String? status;
  final String? kycStatus;
  
  final String? createdDate;
  final String? lastUpdated;
  
  // User info
  final String? username;
  final bool? isActive;
  
  // Summary info
  final int? totalAccounts;
  final int? totalLoans;
  final int? totalCards;

  const CustomerResponseDTO({
    required this.id,
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.status,
    this.kycStatus,
    
    this.createdDate,
    this.lastUpdated,
    this.username,
    this.isActive,
    this.totalAccounts,
    this.totalLoans,
    this.totalCards,
  });

  factory CustomerResponseDTO.fromJson(Map<String, dynamic> json) {
    return CustomerResponseDTO(
      id: json['id'].toString(),
      customerId: json['customerId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      status: json['status'] as String?,
      kycStatus: json['kycStatus'] as String?,
      
      createdDate: json['createdDate'] as String?,
      lastUpdated: json['lastUpdated'] as String?,
      username: json['username'] as String?,
      isActive: json['isActive'] as bool?,
      totalAccounts: json['totalAccounts'] as int?,
      totalLoans: json['totalLoans'] as int?,
      totalCards: json['totalCards'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      if (status != null) 'status': status,
      if (kycStatus != null) 'kycStatus': kycStatus,
      
      if (createdDate != null) 'createdDate': createdDate,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
      if (username != null) 'username': username,
      if (isActive != null) 'isActive': isActive,
      if (totalAccounts != null) 'totalAccounts': totalAccounts,
      if (totalLoans != null) 'totalLoans': totalLoans,
      if (totalCards != null) 'totalCards': totalCards,
    };
  }

  CustomerEntity toEntity() {
    return CustomerEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      dateOfBirth: DateTime.parse(dateOfBirth),
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
    );
  }
}