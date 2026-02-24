class DpsModel {
  final int? id;
  final String? dpsNumber;
  final String? customerId;
  final String? customerName;
  final String? linkedAccountNumber;
  final String? branchName;
  final double? monthlyInstallment;
  final int? tenureMonths;
  final double? interestRate;
  final double? maturityAmount;
  final double? totalDeposited;
  final int? totalInstallmentsPaid;
  final int? pendingInstallments;
  final DateTime? startDate;
  final DateTime? maturityDate;
  final DateTime? nextPaymentDate;
  final String? status;
  final bool? autoDebitEnabled;
  final double? penaltyAmount;
  final int? missedInstallments;
  final String? currency;
  final String? nomineeFirstName;
  final String? nomineeLastName;
  final DateTime? createdDate;

  const DpsModel({
    this.id,
    this.dpsNumber,
    this.customerId,
    this.customerName,
    this.linkedAccountNumber,
    this.branchName,
    this.monthlyInstallment,
    this.tenureMonths,
    this.interestRate,
    this.maturityAmount,
    this.totalDeposited,
    this.totalInstallmentsPaid,
    this.pendingInstallments,
    this.startDate,
    this.maturityDate,
    this.nextPaymentDate,
    this.status,
    this.autoDebitEnabled,
    this.penaltyAmount,
    this.missedInstallments,
    this.currency,
    this.nomineeFirstName,
    this.nomineeLastName,
    this.createdDate,
  });

  factory DpsModel.fromJson(Map<String, dynamic> json) {
    return DpsModel(
      id: json['id'] as int?,
      dpsNumber: json['dpsNumber'] as String?,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      linkedAccountNumber: json['linkedAccountNumber'] as String?,
      branchName: json['branchName'] as String?,
      monthlyInstallment: (json['monthlyInstallment'] as num?)?.toDouble(),
      tenureMonths: json['tenureMonths'] as int?,
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      maturityAmount: (json['maturityAmount'] as num?)?.toDouble(),
      totalDeposited: (json['totalDeposited'] as num?)?.toDouble(),
      totalInstallmentsPaid: json['totalInstallmentsPaid'] as int?,
      pendingInstallments: json['pendingInstallments'] as int?,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      maturityDate: json['maturityDate'] != null
          ? DateTime.tryParse(json['maturityDate'] as String)
          : null,
      nextPaymentDate: json['nextPaymentDate'] != null
          ? DateTime.tryParse(json['nextPaymentDate'] as String)
          : null,
      status: json['status'] as String?,
      autoDebitEnabled: json['autoDebitEnabled'] as bool?,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble(),
      missedInstallments: json['missedInstallments'] as int?,
      currency: json['currency'] as String?,
      nomineeFirstName: json['nomineeFirstName'] as String?,
      nomineeLastName: json['nomineeLastName'] as String?,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (dpsNumber != null) 'dpsNumber': dpsNumber,
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (linkedAccountNumber != null) 'linkedAccountNumber': linkedAccountNumber,
      if (branchName != null) 'branchName': branchName,
      if (monthlyInstallment != null) 'monthlyInstallment': monthlyInstallment,
      if (tenureMonths != null) 'tenureMonths': tenureMonths,
      if (interestRate != null) 'interestRate': interestRate,
      if (maturityAmount != null) 'maturityAmount': maturityAmount,
      if (totalDeposited != null) 'totalDeposited': totalDeposited,
      if (totalInstallmentsPaid != null) 'totalInstallmentsPaid': totalInstallmentsPaid,
      if (pendingInstallments != null) 'pendingInstallments': pendingInstallments,
      if (startDate != null) 'startDate': startDate!.toIso8601String().split('T').first,
      if (maturityDate != null) 'maturityDate': maturityDate!.toIso8601String().split('T').first,
      if (nextPaymentDate != null) 'nextPaymentDate': nextPaymentDate!.toIso8601String().split('T').first,
      if (status != null) 'status': status,
      if (autoDebitEnabled != null) 'autoDebitEnabled': autoDebitEnabled,
      if (penaltyAmount != null) 'penaltyAmount': penaltyAmount,
      if (missedInstallments != null) 'missedInstallments': missedInstallments,
      if (currency != null) 'currency': currency,
      if (nomineeFirstName != null) 'nomineeFirstName': nomineeFirstName,
      if (nomineeLastName != null) 'nomineeLastName': nomineeLastName,
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
    };
  }
}
