class CustomerListItemDTO {
  final String id;
  final String customerId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? status;
  final String? kycStatus;

  const CustomerListItemDTO({
    required this.id,
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.status,
    this.kycStatus,
  });

  factory CustomerListItemDTO.fromJson(Map<String, dynamic> json) {
    return CustomerListItemDTO(
      id: json['id'].toString(),
      customerId: json['customerId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      status: json['status'] as String?,
      kycStatus: json['kycStatus'] as String?,
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
      if (status != null) 'status': status,
      if (kycStatus != null) 'kycStatus': kycStatus,
    };
  }
}