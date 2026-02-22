/// Data Transfer Object for branch information
/// 
/// Contains complete branch details including location, contact information,
/// and operational details.
class BranchResponseDTO {
  /// Internal database ID
  final int id;
  
  /// Unique branch code
  final String branchCode;
  
  /// Branch name
  final String branchName;
  
  /// Street address
  final String address;
  
  /// City
  final String city;
  
  /// State or province
  final String state;
  
  /// Postal/ZIP code
  final String zipCode;
  
  /// Phone number
  final String phone;
  
  /// Email address
  final String email;
  
  /// IFSC code (Indian Financial System Code or equivalent)
  final String ifscCode;
  
  /// Branch status (ACTIVE, INACTIVE, CLOSED)
  final String? status;
  
  /// Working hours (e.g., "Mon-Fri: 9AM-5PM, Sat: 9AM-1PM")
  final String? workingHours;
  
  /// Branch manager's name
  final String? managerName;
  
  /// Latitude for map integration
  final double? latitude;
  
  /// Longitude for map integration
  final double? longitude;
  
  /// Date when branch was established
  final DateTime? establishedDate;

  const BranchResponseDTO({
    required this.id,
    required this.branchCode,
    required this.branchName,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.email,
    required this.ifscCode,
    this.status,
    this.workingHours,
    this.managerName,
    this.latitude,
    this.longitude,
    this.establishedDate,
  });

  /// Create BranchResponseDTO from JSON map
  factory BranchResponseDTO.fromJson(Map<String, dynamic> json) {
    return BranchResponseDTO(
      id: json['id'] as int,
      branchCode: json['branchCode'] as String,
      branchName: json['branchName'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      ifscCode: json['ifscCode'] as String,
      status: json['status'] as String?,
      workingHours: json['workingHours'] as String?,
      managerName: json['managerName'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      establishedDate: json['establishedDate'] != null
          ? DateTime.tryParse(json['establishedDate'] as String)
          : null,
    );
  }

  /// Convert BranchResponseDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchCode': branchCode,
      'branchName': branchName,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
      'ifscCode': ifscCode,
      if (status != null) 'status': status,
      if (workingHours != null) 'workingHours': workingHours,
      if (managerName != null) 'managerName': managerName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (establishedDate != null) 'establishedDate': establishedDate!.toIso8601String(),
    };
  }

  /// Get full address as single string
  String get fullAddress {
    return '$address, $city, $state $zipCode';
  }

  /// Check if branch is active
  bool get isActive {
    return status?.toUpperCase() == 'ACTIVE';
  }

  /// Check if branch has location coordinates
  bool get hasLocation {
    return latitude != null && longitude != null;
  }

  /// Get Google Maps URL for this branch
  String? get googleMapsUrl {
    if (!hasLocation) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Create a copy with modified fields
  BranchResponseDTO copyWith({
    int? id,
    String? branchCode,
    String? branchName,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? ifscCode,
    String? status,
    String? workingHours,
    String? managerName,
    double? latitude,
    double? longitude,
    DateTime? establishedDate,
  }) {
    return BranchResponseDTO(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ifscCode: ifscCode ?? this.ifscCode,
      status: status ?? this.status,
      workingHours: workingHours ?? this.workingHours,
      managerName: managerName ?? this.managerName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      establishedDate: establishedDate ?? this.establishedDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BranchResponseDTO && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BranchResponseDTO(id: $id, code: $branchCode, name: $branchName, city: $city)';
  }
}