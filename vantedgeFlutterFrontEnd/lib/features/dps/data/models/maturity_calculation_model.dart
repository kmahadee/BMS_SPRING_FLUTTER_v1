class MaturityCalculationModel {
  final double? monthlyInstallment;
  final int? tenureMonths;
  final double? interestRate;
  final double? totalDeposit;
  final double? interestEarned;
  final double? maturityAmount;

  const MaturityCalculationModel({
    this.monthlyInstallment,
    this.tenureMonths,
    this.interestRate,
    this.totalDeposit,
    this.interestEarned,
    this.maturityAmount,
  });

  factory MaturityCalculationModel.fromJson(Map<String, dynamic> json) {
    return MaturityCalculationModel(
      monthlyInstallment: (json['monthlyInstallment'] as num?)?.toDouble(),
      tenureMonths: json['tenureMonths'] as int?,
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      totalDeposit: (json['totalDeposit'] as num?)?.toDouble(),
      interestEarned: (json['interestEarned'] as num?)?.toDouble(),
      maturityAmount: (json['maturityAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (monthlyInstallment != null) 'monthlyInstallment': monthlyInstallment,
      if (tenureMonths != null) 'tenureMonths': tenureMonths,
      if (interestRate != null) 'interestRate': interestRate,
      if (totalDeposit != null) 'totalDeposit': totalDeposit,
      if (interestEarned != null) 'interestEarned': interestEarned,
      if (maturityAmount != null) 'maturityAmount': maturityAmount,
    };
  }
}
