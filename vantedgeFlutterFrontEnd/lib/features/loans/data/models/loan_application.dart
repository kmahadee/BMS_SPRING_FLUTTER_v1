import 'loan_enums.dart';

/// Maps to [LoanApplicationRequestDTO].
///
/// Required fields: customerId, loanType, loanAmount, tenureMonths,
/// annualInterestRate, accountNumber, applicantName, age, monthlyIncome,
/// employmentType.
///
/// Optional fields include collateral, LC-specific (lcNumber, beneficiaryName,
/// etc.) and business-specific (industryType, businessTurnover, etc.).
class LoanApplicationModel {
  // ── Required fields ──────────────────────────────────────────────────────
  final String customerId;
  final LoanType loanType;

  /// Minimum: 50,000 | Maximum: 10,000,000
  final double loanAmount;

  /// Minimum: 6 months | Maximum: 360 months
  final int tenureMonths;

  /// Minimum: 5.0% | Maximum: 25.0%
  final double annualInterestRate;

  final String accountNumber;
  final String applicantName;

  /// Minimum: 21 | Maximum: 65
  final int age;

  /// Minimum: 1,000
  final double monthlyIncome;

  final EmploymentType employmentType;

  // ── Optional / common fields ─────────────────────────────────────────────
  final ApplicantType? applicantType;
  final String? collateralType;
  final double? collateralValue;
  final String? collateralDescription;

  /// Maximum 500 characters.
  final String? purpose;

  // ── LC-specific optional fields ───────────────────────────────────────────
  final String? lcNumber;
  final String? beneficiaryName;
  final String? beneficiaryBank;
  final DateTime? lcExpiryDate;
  final double? lcAmount;
  final String? purposeOfLC;
  final String? paymentTerms;

  // ── Business-specific optional fields ────────────────────────────────────
  final String? industryType;
  final String? businessRegistrationNumber;
  final double? businessTurnover;

  // ── Document types list ───────────────────────────────────────────────────
  final List<String>? documentTypes;

  const LoanApplicationModel({
    required this.customerId,
    required this.loanType,
    required this.loanAmount,
    required this.tenureMonths,
    required this.annualInterestRate,
    required this.accountNumber,
    required this.applicantName,
    required this.age,
    required this.monthlyIncome,
    required this.employmentType,
    this.applicantType,
    this.collateralType,
    this.collateralValue,
    this.collateralDescription,
    this.purpose,
    this.lcNumber,
    this.beneficiaryName,
    this.beneficiaryBank,
    this.lcExpiryDate,
    this.lcAmount,
    this.purposeOfLC,
    this.paymentTerms,
    this.industryType,
    this.businessRegistrationNumber,
    this.businessTurnover,
    this.documentTypes,
  });

  factory LoanApplicationModel.fromJson(Map<String, dynamic> json) {
    return LoanApplicationModel(
      customerId: json['customerId'] as String,
      loanType: LoanType.fromString(json['loanType'] as String),
      loanAmount: (json['loanAmount'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      annualInterestRate: (json['annualInterestRate'] as num).toDouble(),
      accountNumber: json['accountNumber'] as String,
      applicantName: json['applicantName'] as String,
      age: json['age'] as int,
      monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
      employmentType: EmploymentType.fromString(json['employmentType'] as String),
      applicantType: json['applicantType'] != null
          ? ApplicantType.fromString(json['applicantType'] as String)
          : null,
      collateralType: json['collateralType'] as String?,
      collateralValue: (json['collateralValue'] as num?)?.toDouble(),
      collateralDescription: json['collateralDescription'] as String?,
      purpose: json['purpose'] as String?,
      lcNumber: json['lcNumber'] as String?,
      beneficiaryName: json['beneficiaryName'] as String?,
      beneficiaryBank: json['beneficiaryBank'] as String?,
      lcExpiryDate: json['lcExpiryDate'] != null
          ? DateTime.tryParse(json['lcExpiryDate'] as String)
          : null,
      lcAmount: (json['lcAmount'] as num?)?.toDouble(),
      purposeOfLC: json['purposeOfLC'] as String?,
      paymentTerms: json['paymentTerms'] as String?,
      industryType: json['industryType'] as String?,
      businessRegistrationNumber: json['businessRegistrationNumber'] as String?,
      businessTurnover: (json['businessTurnover'] as num?)?.toDouble(),
      documentTypes: (json['documentTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'loanType': loanType.toApiString(),
      'loanAmount': loanAmount,
      'tenureMonths': tenureMonths,
      'annualInterestRate': annualInterestRate,
      'accountNumber': accountNumber,
      'applicantName': applicantName,
      'age': age,
      'monthlyIncome': monthlyIncome,
      'employmentType': employmentType.toApiString(),
      if (applicantType != null) 'applicantType': applicantType!.toApiString(),
      if (collateralType != null) 'collateralType': collateralType,
      if (collateralValue != null) 'collateralValue': collateralValue,
      if (collateralDescription != null)
        'collateralDescription': collateralDescription,
      if (purpose != null) 'purpose': purpose,
      if (lcNumber != null) 'lcNumber': lcNumber,
      if (beneficiaryName != null) 'beneficiaryName': beneficiaryName,
      if (beneficiaryBank != null) 'beneficiaryBank': beneficiaryBank,
      if (lcExpiryDate != null)
        'lcExpiryDate': lcExpiryDate!.toIso8601String().split('T').first,
      if (lcAmount != null) 'lcAmount': lcAmount,
      if (purposeOfLC != null) 'purposeOfLC': purposeOfLC,
      if (paymentTerms != null) 'paymentTerms': paymentTerms,
      if (industryType != null) 'industryType': industryType,
      if (businessRegistrationNumber != null)
        'businessRegistrationNumber': businessRegistrationNumber,
      if (businessTurnover != null) 'businessTurnover': businessTurnover,
      if (documentTypes != null) 'documentTypes': documentTypes,
    };
  }

  @override
  String toString() =>
      'LoanApplicationModel(customerId: $customerId, type: ${loanType.displayName}, '
      'amount: $loanAmount, tenure: ${tenureMonths}m)';
}

// ---------------------------------------------------------------------------

/// Maps to [LoanRepaymentRequestDTO].
class LoanRepaymentRequestModel {
  final String loanId;
  final double paymentAmount;
  final DateTime paymentDate;
  final LoanPaymentMode paymentMode;
  final String? transactionReference;

  const LoanRepaymentRequestModel({
    required this.loanId,
    required this.paymentAmount,
    required this.paymentDate,
    required this.paymentMode,
    this.transactionReference,
  });

  factory LoanRepaymentRequestModel.fromJson(Map<String, dynamic> json) {
    return LoanRepaymentRequestModel(
      loanId: json['loanId'] as String,
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      paymentMode: LoanPaymentMode.fromString(json['paymentMode'] as String),
      transactionReference: json['transactionReference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'paymentAmount': paymentAmount,
      'paymentDate': paymentDate.toIso8601String().split('T').first,
      'paymentMode': paymentMode.toApiString(),
      if (transactionReference != null)
        'transactionReference': transactionReference,
    };
  }
}

// ---------------------------------------------------------------------------

/// Maps to [LoanApprovalRequestDTO].
class LoanApprovalRequestModel {
  final String loanId;

  /// Must be 'APPROVED' or 'REJECTED'.
  final ApprovalStatus approvalStatus;

  /// Maximum 1000 characters.
  final String? comments;

  /// Maximum 1000 characters.
  final String? approvalConditions;

  final double? interestRateModification;
  final String? rejectionReason;

  const LoanApprovalRequestModel({
    required this.loanId,
    required this.approvalStatus,
    this.comments,
    this.approvalConditions,
    this.interestRateModification,
    this.rejectionReason,
  });

  factory LoanApprovalRequestModel.fromJson(Map<String, dynamic> json) {
    return LoanApprovalRequestModel(
      loanId: json['loanId'] as String,
      approvalStatus: ApprovalStatus.fromString(json['approvalStatus'] as String),
      comments: json['comments'] as String?,
      approvalConditions: json['approvalConditions'] as String?,
      interestRateModification:
          (json['interestRateModification'] as num?)?.toDouble(),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'approvalStatus': approvalStatus.toApiString(),
      if (comments != null) 'comments': comments,
      if (approvalConditions != null) 'approvalConditions': approvalConditions,
      if (interestRateModification != null)
        'interestRateModification': interestRateModification,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }
}

// ---------------------------------------------------------------------------

/// Maps to [LoanDisbursementRequestDTO].
class LoanDisbursementRequestModel {
  final String loanId;
  final double disbursementAmount;
  final String accountNumber;
  final String? bankDetails;
  final DateTime? scheduledDate;

  const LoanDisbursementRequestModel({
    required this.loanId,
    required this.disbursementAmount,
    required this.accountNumber,
    this.bankDetails,
    this.scheduledDate,
  });

  factory LoanDisbursementRequestModel.fromJson(Map<String, dynamic> json) {
    return LoanDisbursementRequestModel(
      loanId: json['loanId'] as String,
      disbursementAmount: (json['disbursementAmount'] as num).toDouble(),
      accountNumber: json['accountNumber'] as String,
      bankDetails: json['bankDetails'] as String?,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'disbursementAmount': disbursementAmount,
      'accountNumber': accountNumber,
      if (bankDetails != null) 'bankDetails': bankDetails,
      if (scheduledDate != null)
        'scheduledDate': scheduledDate!.toIso8601String().split('T').first,
    };
  }
}

// ---------------------------------------------------------------------------

/// Maps to [LoanForeclosureRequestDTO].
class LoanForeclosureRequestModel {
  final String loanId;
  final DateTime foreclosureDate;
  final String settlementAccountNumber;

  const LoanForeclosureRequestModel({
    required this.loanId,
    required this.foreclosureDate,
    required this.settlementAccountNumber,
  });

  factory LoanForeclosureRequestModel.fromJson(Map<String, dynamic> json) {
    return LoanForeclosureRequestModel(
      loanId: json['loanId'] as String,
      foreclosureDate: DateTime.parse(json['foreclosureDate'] as String),
      settlementAccountNumber: json['settlementAccountNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'foreclosureDate': foreclosureDate.toIso8601String().split('T').first,
      'settlementAccountNumber': settlementAccountNumber,
    };
  }
}
