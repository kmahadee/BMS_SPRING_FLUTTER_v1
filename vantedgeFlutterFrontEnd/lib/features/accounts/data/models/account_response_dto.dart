import 'account_type.dart';
import 'account_status.dart';

/// Data Transfer Object for complete account details
/// 
/// Contains comprehensive account information including customer details,
/// branch information, balance details, nominee information, and account metadata.
class AccountResponseDTO {
  /// Internal database ID
  final int? id;
  
  /// Unique account number
  final String accountNumber;
  
  /// Type of account (SAVINGS, CURRENT, SALARY, FD)
  final AccountType accountType;
  
  /// Display name for the account
  final String accountName;
  
  /// Customer ID who owns this account
  final String customerId;
  
  /// Customer's full name
  final String? customerName;
  
  /// Branch ID managing this account
  final int branchId;
  
  /// Branch code
  final String branchCode;
  
  /// Branch name
  final String? branchName;
  
  /// Branch city
  final String? branchCity;
  
  /// Current balance in the account
  final double currentBalance;
  
  /// Available balance for withdrawal/transfer
  final double availableBalance;
  
  /// Interest rate applicable to this account
  final double interestRate;
  
  /// Minimum balance required to maintain
  final double minimumBalance;
  
  /// Currency code (e.g., USD, EUR, BDT)
  final String? currency;
  
  /// Current status of the account
  final AccountStatus status;
  
  /// Date when the account was opened
  final DateTime? openDate;
  
  /// Date of the last transaction
  final DateTime? lastTransactionDate;
  
  /// Nominee's first name
  final String? nomineeFirstName;
  
  /// Nominee's last name
  final String? nomineeLastName;
  
  /// Nominee's relationship to account holder
  final String? nomineeRelationship;
  
  /// Nominee's phone number
  final String? nomineePhone;
  
  /// Type of account holder (INDIVIDUAL, JOINT, BUSINESS)
  final String? accountHolderType;
  
  /// Date when account was created in system
  final DateTime? createdDate;
  
  /// Date of last update
  final DateTime? lastModifiedDate;

  const AccountResponseDTO({
    this.id,
    required this.accountNumber,
    required this.accountType,
    required this.accountName,
    required this.customerId,
    this.customerName,
    required this.branchId,
    required this.branchCode,
    this.branchName,
    this.branchCity,
    required this.currentBalance,
    required this.availableBalance,
    required this.interestRate,
    required this.minimumBalance,
    this.currency,
    required this.status,
    this.openDate,
    this.lastTransactionDate,
    this.nomineeFirstName,
    this.nomineeLastName,
    this.nomineeRelationship,
    this.nomineePhone,
    this.accountHolderType,
    this.createdDate,
    this.lastModifiedDate,
  });

  /// Create AccountResponseDTO from JSON map
  factory AccountResponseDTO.fromJson(Map<String, dynamic> json) {
    return AccountResponseDTO(
      id: json['id'] as int?,
      accountNumber: json['accountNumber'] as String,
      accountType: AccountType.fromValue(json['accountType'] as String),
      accountName: json['accountName'] as String? ?? '',
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String?,
      branchId: json['branchId'] as int,
      branchCode: json['branchCode'] as String,
      branchName: json['branchName'] as String?,
      branchCity: json['branchCity'] as String?,
      currentBalance: (json['balance'] ?? json['currentBalance'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? json['balance'] ?? 0).toDouble(),
      interestRate: (json['interestRate'] ?? 0).toDouble(),
      minimumBalance: (json['minimumBalance'] ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'BDT',
      status: AccountStatus.fromValue(json['status'] as String? ?? 'INACTIVE'),
      openDate: json['openDate'] != null ? DateTime.tryParse(json['openDate'] as String) : null,
      lastTransactionDate: json['lastTransactionDate'] != null 
          ? DateTime.tryParse(json['lastTransactionDate'] as String) 
          : null,
      nomineeFirstName: json['nomineeFirstName'] as String?,
      nomineeLastName: json['nomineeLastName'] as String?,
      nomineeRelationship: json['nomineeRelationship'] as String?,
      nomineePhone: json['nomineePhone'] as String?,
      accountHolderType: json['accountHolderType'] as String?,
      createdDate: json['createdDate'] != null 
          ? DateTime.tryParse(json['createdDate'] as String) 
          : null,
      lastModifiedDate: json['lastModifiedDate'] != null 
          ? DateTime.tryParse(json['lastModifiedDate'] as String) 
          : null,
    );
  }

  /// Convert AccountResponseDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'accountNumber': accountNumber,
      'accountType': accountType.value,
      'accountName': accountName,
      'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      'branchId': branchId,
      'branchCode': branchCode,
      if (branchName != null) 'branchName': branchName,
      if (branchCity != null) 'branchCity': branchCity,
      'balance': currentBalance,
      'currentBalance': currentBalance,
      'availableBalance': availableBalance,
      'interestRate': interestRate,
      'minimumBalance': minimumBalance,
      if (currency != null) 'currency': currency,
      'status': status.value,
      if (openDate != null) 'openDate': openDate!.toIso8601String(),
      if (lastTransactionDate != null) 
        'lastTransactionDate': lastTransactionDate!.toIso8601String(),
      if (nomineeFirstName != null) 'nomineeFirstName': nomineeFirstName,
      if (nomineeLastName != null) 'nomineeLastName': nomineeLastName,
      if (nomineeRelationship != null) 'nomineeRelationship': nomineeRelationship,
      if (nomineePhone != null) 'nomineePhone': nomineePhone,
      if (accountHolderType != null) 'accountHolderType': accountHolderType,
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
      if (lastModifiedDate != null) 
        'lastModifiedDate': lastModifiedDate!.toIso8601String(),
    };
  }

  /// Get full nominee name
  String? get fullNomineeName {
    if (nomineeFirstName == null && nomineeLastName == null) return null;
    return '${nomineeFirstName ?? ''} ${nomineeLastName ?? ''}'.trim();
  }

  /// Check if account has nominee information
  bool get hasNominee {
    return nomineeFirstName != null || nomineeLastName != null;
  }

  /// Create a copy with modified fields
  AccountResponseDTO copyWith({
    int? id,
    String? accountNumber,
    AccountType? accountType,
    String? accountName,
    String? customerId,
    String? customerName,
    int? branchId,
    String? branchCode,
    String? branchName,
    String? branchCity,
    double? currentBalance,
    double? availableBalance,
    double? interestRate,
    double? minimumBalance,
    String? currency,
    AccountStatus? status,
    DateTime? openDate,
    DateTime? lastTransactionDate,
    String? nomineeFirstName,
    String? nomineeLastName,
    String? nomineeRelationship,
    String? nomineePhone,
    String? accountHolderType,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) {
    return AccountResponseDTO(
      id: id ?? this.id,
      accountNumber: accountNumber ?? this.accountNumber,
      accountType: accountType ?? this.accountType,
      accountName: accountName ?? this.accountName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      branchId: branchId ?? this.branchId,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      branchCity: branchCity ?? this.branchCity,
      currentBalance: currentBalance ?? this.currentBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      interestRate: interestRate ?? this.interestRate,
      minimumBalance: minimumBalance ?? this.minimumBalance,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      openDate: openDate ?? this.openDate,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      nomineeFirstName: nomineeFirstName ?? this.nomineeFirstName,
      nomineeLastName: nomineeLastName ?? this.nomineeLastName,
      nomineeRelationship: nomineeRelationship ?? this.nomineeRelationship,
      nomineePhone: nomineePhone ?? this.nomineePhone,
      accountHolderType: accountHolderType ?? this.accountHolderType,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountResponseDTO && other.accountNumber == accountNumber;
  }

  @override
  int get hashCode => accountNumber.hashCode;

  @override
  String toString() {
    return 'AccountResponseDTO(accountNumber: $accountNumber, type: ${accountType.value}, balance: $currentBalance, status: ${status.value})';
  }
}