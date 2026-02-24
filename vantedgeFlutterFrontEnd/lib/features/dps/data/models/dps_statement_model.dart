import 'dps_installment_model.dart';

class DpsStatementModel {
  final String? dpsNumber;
  final String? customerName;
  final double? monthlyInstallment;
  final int? totalInstallments;
  final int? paidInstallments;
  final int? pendingInstallments;
  final double? totalDeposited;
  final double? maturityAmount;
  final DateTime? maturityDate;
  final List<DpsInstallmentModel>? installments;

  const DpsStatementModel({
    this.dpsNumber,
    this.customerName,
    this.monthlyInstallment,
    this.totalInstallments,
    this.paidInstallments,
    this.pendingInstallments,
    this.totalDeposited,
    this.maturityAmount,
    this.maturityDate,
    this.installments,
  });

  factory DpsStatementModel.fromJson(Map<String, dynamic> json) {
    final rawInstallments = json['installments'] as List<dynamic>?;
    return DpsStatementModel(
      dpsNumber: json['dpsNumber'] as String?,
      customerName: json['customerName'] as String?,
      monthlyInstallment: (json['monthlyInstallment'] as num?)?.toDouble(),
      totalInstallments: json['totalInstallments'] as int?,
      paidInstallments: json['paidInstallments'] as int?,
      pendingInstallments: json['pendingInstallments'] as int?,
      totalDeposited: (json['totalDeposited'] as num?)?.toDouble(),
      maturityAmount: (json['maturityAmount'] as num?)?.toDouble(),
      maturityDate: json['maturityDate'] != null
          ? DateTime.tryParse(json['maturityDate'] as String)
          : null,
      installments: rawInstallments
          ?.map((e) => DpsInstallmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dpsNumber != null) 'dpsNumber': dpsNumber,
      if (customerName != null) 'customerName': customerName,
      if (monthlyInstallment != null) 'monthlyInstallment': monthlyInstallment,
      if (totalInstallments != null) 'totalInstallments': totalInstallments,
      if (paidInstallments != null) 'paidInstallments': paidInstallments,
      if (pendingInstallments != null) 'pendingInstallments': pendingInstallments,
      if (totalDeposited != null) 'totalDeposited': totalDeposited,
      if (maturityAmount != null) 'maturityAmount': maturityAmount,
      if (maturityDate != null)
        'maturityDate': maturityDate!.toIso8601String().split('T').first,
      if (installments != null)
        'installments': installments!.map((i) => i.toJson()).toList(),
    };
  }
}
