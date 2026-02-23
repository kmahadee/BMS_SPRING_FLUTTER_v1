/// Pure Dart utility for loan EMI calculations.
/// No Flutter or business-logic dependencies — safe to use in any layer.
class LoanCalculator {
  LoanCalculator._();

  /// Calculates the monthly EMI using the standard reducing-balance formula:
  ///   EMI = P × r × (1 + r)^n / ((1 + r)^n − 1)
  ///
  /// where:
  ///   P = [principal]
  ///   r = [annualRate] / 12 / 100  (monthly rate)
  ///   n = [tenureMonths]
  ///
  /// Returns 0 if any parameter is non-positive.
  static double calculateEMI({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    if (principal <= 0 || annualRate <= 0 || tenureMonths <= 0) return 0.0;

    final double r = annualRate / 12 / 100;
    final double power = _pow(1 + r, tenureMonths);
    final double emi = principal * r * power / (power - 1);
    return emi;
  }

  /// Total repayment amount = EMI × tenure.
  static double calculateTotalAmount({
    required double emi,
    required int tenureMonths,
  }) {
    if (emi <= 0 || tenureMonths <= 0) return 0.0;
    return emi * tenureMonths;
  }

  /// Total interest paid = totalAmount − principal.
  static double calculateTotalInterest({
    required double totalAmount,
    required double principal,
  }) {
    final interest = totalAmount - principal;
    return interest < 0 ? 0.0 : interest;
  }

  /// Convenience all-in-one result for UI display.
  static LoanCalculationResult calculate({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final emi = calculateEMI(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
    final total = calculateTotalAmount(emi: emi, tenureMonths: tenureMonths);
    final interest = calculateTotalInterest(
      totalAmount: total,
      principal: principal,
    );
    return LoanCalculationResult(
      emi: emi,
      totalAmount: total,
      totalInterest: interest,
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static double _pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

/// Immutable value object that holds all results for a single EMI calculation.
class LoanCalculationResult {
  final double emi;
  final double totalAmount;
  final double totalInterest;
  final double principal;
  final double annualRate;
  final int tenureMonths;

  const LoanCalculationResult({
    required this.emi,
    required this.totalAmount,
    required this.totalInterest,
    required this.principal,
    required this.annualRate,
    required this.tenureMonths,
  });

  /// Interest as a percentage of principal.
  double get interestPercentOfPrincipal =>
      principal > 0 ? (totalInterest / principal) * 100 : 0;

  /// Fraction of total repayment that is interest (0–1).
  double get interestRatio =>
      totalAmount > 0 ? totalInterest / totalAmount : 0;

  @override
  String toString() =>
      'LoanCalculationResult(emi: ${emi.toStringAsFixed(2)}, '
      'total: ${totalAmount.toStringAsFixed(2)}, '
      'interest: ${totalInterest.toStringAsFixed(2)})';
}
