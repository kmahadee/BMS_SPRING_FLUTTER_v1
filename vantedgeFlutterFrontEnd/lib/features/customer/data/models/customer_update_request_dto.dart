class CustomerUpdateRequestDTO {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  // final String? image;
  final String? status;
  final String? kycStatus;

  const CustomerUpdateRequestDTO({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    // this.image,
    this.status,
    this.kycStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      // if (image != null) 'image': image,
      if (status != null) 'status': status,
      if (kycStatus != null) 'kycStatus': kycStatus,
    };
  }
}