import 'loan_enums.dart';

/// Maps to [LoanResponseDTO] — the full loan detail response.
class LoanResponseModel {
  final String loanId;
  final LoanType loanType;
  final LoanStatus loanStatus;
  final ApprovalStatus approvalStatus;
  final double principal;
  final double annualInterestRate;
  final int tenureMonths;
  final double? monthlyEMI;
  final double? totalAmount;
  final double? totalInterest;
  final double? outstandingBalance;
  final double? disbursedAmount;
  final double? approvedAmount;
  final int? creditScore;
  final String? eligibilityStatus;
  final DateTime? applicationDate;
  final DateTime? approvedDate;
  final DateTime? actualDisbursementDate;
  final DateTime? createdDate;
  final String? customerId;
  final String? customerName;
  final String? accountNumber;
  final String? collateralType;
  final double? collateralValue;
  final String? purpose;
  final String? approvalConditions;
  final DisbursementStatus? disbursementStatus;

  // LC-specific fields
  final String? lcNumber;
  final String? beneficiaryName;

  // Business-specific fields
  final String? industryType;
  final double? businessTurnover;

  const LoanResponseModel({
    required this.loanId,
    required this.loanType,
    required this.loanStatus,
    required this.approvalStatus,
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    this.monthlyEMI,
    this.totalAmount,
    this.totalInterest,
    this.outstandingBalance,
    this.disbursedAmount,
    this.approvedAmount,
    this.creditScore,
    this.eligibilityStatus,
    this.applicationDate,
    this.approvedDate,
    this.actualDisbursementDate,
    this.createdDate,
    this.customerId,
    this.customerName,
    this.accountNumber,
    this.collateralType,
    this.collateralValue,
    this.purpose,
    this.approvalConditions,
    this.disbursementStatus,
    this.lcNumber,
    this.beneficiaryName,
    this.industryType,
    this.businessTurnover,
  });

  factory LoanResponseModel.fromJson(Map<String, dynamic> json) {
    return LoanResponseModel(
      loanId: json['loanId'] as String,
      loanType: LoanType.fromString(json['loanType'] as String),
      loanStatus: LoanStatus.fromString(json['loanStatus'] as String),
      approvalStatus: ApprovalStatus.fromString(json['approvalStatus'] as String),
      principal: (json['principal'] as num).toDouble(),
      annualInterestRate: (json['annualInterestRate'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      monthlyEMI: (json['monthlyEMI'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      totalInterest: (json['totalInterest'] as num?)?.toDouble(),
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble(),
      disbursedAmount: (json['disbursedAmount'] as num?)?.toDouble(),
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
      creditScore: json['creditScore'] as int?,
      eligibilityStatus: json['eligibilityStatus'] as String?,
      applicationDate: json['applicationDate'] != null
          ? DateTime.tryParse(json['applicationDate'] as String)
          : null,
      approvedDate: json['approvedDate'] != null
          ? DateTime.tryParse(json['approvedDate'] as String)
          : null,
      actualDisbursementDate: json['actualDisbursementDate'] != null
          ? DateTime.tryParse(json['actualDisbursementDate'] as String)
          : null,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'] as String)
          : null,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      collateralType: json['collateralType'] as String?,
      collateralValue: (json['collateralValue'] as num?)?.toDouble(),
      purpose: json['purpose'] as String?,
      approvalConditions: json['approvalConditions'] as String?,
      disbursementStatus: json['disbursementStatus'] != null
          ? DisbursementStatus.fromString(json['disbursementStatus'] as String)
          : null,
      lcNumber: json['lcNumber'] as String?,
      beneficiaryName: json['beneficiaryName'] as String?,
      industryType: json['industryType'] as String?,
      businessTurnover: (json['businessTurnover'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'loanType': loanType.toApiString(),
      'loanStatus': loanStatus.toApiString(),
      'approvalStatus': approvalStatus.toApiString(),
      'principal': principal,
      'annualInterestRate': annualInterestRate,
      'tenureMonths': tenureMonths,
      if (monthlyEMI != null) 'monthlyEMI': monthlyEMI,
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (totalInterest != null) 'totalInterest': totalInterest,
      if (outstandingBalance != null) 'outstandingBalance': outstandingBalance,
      if (disbursedAmount != null) 'disbursedAmount': disbursedAmount,
      if (approvedAmount != null) 'approvedAmount': approvedAmount,
      if (creditScore != null) 'creditScore': creditScore,
      if (eligibilityStatus != null) 'eligibilityStatus': eligibilityStatus,
      if (applicationDate != null)
        'applicationDate': applicationDate!.toIso8601String().split('T').first,
      if (approvedDate != null)
        'approvedDate': approvedDate!.toIso8601String().split('T').first,
      if (actualDisbursementDate != null)
        'actualDisbursementDate':
            actualDisbursementDate!.toIso8601String().split('T').first,
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (collateralType != null) 'collateralType': collateralType,
      if (collateralValue != null) 'collateralValue': collateralValue,
      if (purpose != null) 'purpose': purpose,
      if (approvalConditions != null) 'approvalConditions': approvalConditions,
      if (disbursementStatus != null)
        'disbursementStatus': disbursementStatus!.toApiString(),
      if (lcNumber != null) 'lcNumber': lcNumber,
      if (beneficiaryName != null) 'beneficiaryName': beneficiaryName,
      if (industryType != null) 'industryType': industryType,
      if (businessTurnover != null) 'businessTurnover': businessTurnover,
    };
  }

  LoanResponseModel copyWith({
    String? loanId,
    LoanType? loanType,
    LoanStatus? loanStatus,
    ApprovalStatus? approvalStatus,
    double? principal,
    double? annualInterestRate,
    int? tenureMonths,
    double? monthlyEMI,
    double? totalAmount,
    double? totalInterest,
    double? outstandingBalance,
    double? disbursedAmount,
    double? approvedAmount,
    int? creditScore,
    String? eligibilityStatus,
    DateTime? applicationDate,
    DateTime? approvedDate,
    DateTime? actualDisbursementDate,
    DateTime? createdDate,
    String? customerId,
    String? customerName,
    String? accountNumber,
    String? collateralType,
    double? collateralValue,
    String? purpose,
    String? approvalConditions,
    DisbursementStatus? disbursementStatus,
    String? lcNumber,
    String? beneficiaryName,
    String? industryType,
    double? businessTurnover,
  }) {
    return LoanResponseModel(
      loanId: loanId ?? this.loanId,
      loanType: loanType ?? this.loanType,
      loanStatus: loanStatus ?? this.loanStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      principal: principal ?? this.principal,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      monthlyEMI: monthlyEMI ?? this.monthlyEMI,
      totalAmount: totalAmount ?? this.totalAmount,
      totalInterest: totalInterest ?? this.totalInterest,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      disbursedAmount: disbursedAmount ?? this.disbursedAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      creditScore: creditScore ?? this.creditScore,
      eligibilityStatus: eligibilityStatus ?? this.eligibilityStatus,
      applicationDate: applicationDate ?? this.applicationDate,
      approvedDate: approvedDate ?? this.approvedDate,
      actualDisbursementDate:
          actualDisbursementDate ?? this.actualDisbursementDate,
      createdDate: createdDate ?? this.createdDate,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      accountNumber: accountNumber ?? this.accountNumber,
      collateralType: collateralType ?? this.collateralType,
      collateralValue: collateralValue ?? this.collateralValue,
      purpose: purpose ?? this.purpose,
      approvalConditions: approvalConditions ?? this.approvalConditions,
      disbursementStatus: disbursementStatus ?? this.disbursementStatus,
      lcNumber: lcNumber ?? this.lcNumber,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      industryType: industryType ?? this.industryType,
      businessTurnover: businessTurnover ?? this.businessTurnover,
    );
  }

  @override
  String toString() => 'LoanResponseModel(loanId: $loanId, type: ${loanType.displayName}, '
      'status: ${loanStatus.displayName}, principal: $principal)';
}

// ---------------------------------------------------------------------------

/// Maps to [LoanListItemDTO] — the compact list-view loan model.
class LoanListItemModel {
  final String loanId;
  final LoanType loanType;
  final LoanStatus loanStatus;
  final ApprovalStatus approvalStatus;
  final double principal;
  final double? outstandingBalance;
  final double? monthlyEMI;
  final DateTime? applicationDate;
  final String? customerName;
  final String? customerId;

  const LoanListItemModel({
    required this.loanId,
    required this.loanType,
    required this.loanStatus,
    required this.approvalStatus,
    required this.principal,
    this.outstandingBalance,
    this.monthlyEMI,
    this.applicationDate,
    this.customerName,
    this.customerId,
  });

  factory LoanListItemModel.fromJson(Map<String, dynamic> json) {
    return LoanListItemModel(
      loanId: json['loanId'] as String,
      loanType: LoanType.fromString(json['loanType'] as String),
      loanStatus: LoanStatus.fromString(json['loanStatus'] as String),
      approvalStatus: ApprovalStatus.fromString(json['approvalStatus'] as String),
      principal: (json['principal'] as num).toDouble(),
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble(),
      monthlyEMI: (json['monthlyEMI'] as num?)?.toDouble(),
      applicationDate: json['applicationDate'] != null
          ? DateTime.tryParse(json['applicationDate'] as String)
          : null,
      customerName: json['customerName'] as String?,
      customerId: json['customerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'loanType': loanType.toApiString(),
      'loanStatus': loanStatus.toApiString(),
      'approvalStatus': approvalStatus.toApiString(),
      'principal': principal,
      if (outstandingBalance != null) 'outstandingBalance': outstandingBalance,
      if (monthlyEMI != null) 'monthlyEMI': monthlyEMI,
      if (applicationDate != null)
        'applicationDate': applicationDate!.toIso8601String().split('T').first,
      if (customerName != null) 'customerName': customerName,
      if (customerId != null) 'customerId': customerId,
    };
  }

  @override
  String toString() =>
      'LoanListItemModel(loanId: $loanId, type: ${loanType.displayName}, '
      'status: ${loanStatus.displayName})';
}
