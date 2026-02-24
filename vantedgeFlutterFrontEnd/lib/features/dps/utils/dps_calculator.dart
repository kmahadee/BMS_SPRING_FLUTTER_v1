/// Pure-Dart, offline DPS maturity calculator.
///
/// DPS (Deposit Pension Scheme) maturity is calculated using simple interest
/// compounded annually on the cumulative monthly deposits:
///
///   maturityAmount = Σ(monthly_installment × (1 + r)^(n/12))
///
/// where r = annual interest rate / 100, and n = remaining months for each
/// installment. The sum telescopes to the closed form used below.
///
/// This matches the standard formula used by Bangladeshi and South Asian banks.
library;

class DpsCalculator {
  DpsCalculator._();

  // ── Core calculation ───────────────────────────────────────────────────────

  /// Calculate full DPS maturity details.
  ///
  /// [monthlyInstallment] — amount deposited each month (>= 100)
  /// [tenureMonths]       — total tenure in months  (6 – 120)
  /// [annualInterestRate] — annual interest rate in % (e.g. 8.0 for 8%)
  static DpsCalculationResult calculate({
    required double monthlyInstallment,
    required int    tenureMonths,
    required double annualInterestRate,
  }) {
    if (monthlyInstallment <= 0 || tenureMonths <= 0 || annualInterestRate <= 0) {
      return DpsCalculationResult.zero(
        monthlyInstallment: monthlyInstallment,
        tenureMonths:       tenureMonths,
        annualInterestRate: annualInterestRate,
      );
    }

    final double totalDeposit  = monthlyInstallment * tenureMonths;
    final double maturityAmount = _computeMaturity(
      monthly:  monthlyInstallment,
      months:   tenureMonths,
      rate:     annualInterestRate,
    );

    final double interestEarned    = maturityAmount - totalDeposit;
    final double effectiveYield    =
        totalDeposit > 0 ? (maturityAmount / totalDeposit - 1) * 100 : 0.0;

    final DateTime maturityDate    =
        DateTime.now().add(Duration(days: (tenureMonths * 30.4375).round()));

    return DpsCalculationResult(
      monthlyInstallment: monthlyInstallment,
      tenureMonths:       tenureMonths,
      annualInterestRate: annualInterestRate,
      totalDeposit:       totalDeposit,
      interestEarned:     interestEarned < 0 ? 0 : interestEarned,
      maturityAmount:     maturityAmount,
      effectiveAnnualYield: effectiveYield,
      projectedMaturityDate: maturityDate,
    );
  }

  // ── Formula ────────────────────────────────────────────────────────────────

  /// Compound DPS maturity:
  ///   M = P × r/12 × ((1 + r/12)^n - 1) / (r/12)
  /// which simplifies to the future value of an ordinary annuity.
  static double _computeMaturity({
    required double monthly,
    required int    months,
    required double rate,
  }) {
    final double r = rate / 100 / 12; // monthly rate
    if (r == 0) return monthly * months;

    final double factor = _pow(1 + r, months);
    // FV of ordinary annuity
    return monthly * (factor - 1) / r;
  }

  static double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}

// ── Result model ─────────────────────────────────────────────────────────────

class DpsCalculationResult {
  final double   monthlyInstallment;
  final int      tenureMonths;
  final double   annualInterestRate;
  final double   totalDeposit;
  final double   interestEarned;
  final double   maturityAmount;
  final double   effectiveAnnualYield;    // % gain over total deposit
  final DateTime projectedMaturityDate;

  const DpsCalculationResult({
    required this.monthlyInstallment,
    required this.tenureMonths,
    required this.annualInterestRate,
    required this.totalDeposit,
    required this.interestEarned,
    required this.maturityAmount,
    required this.effectiveAnnualYield,
    required this.projectedMaturityDate,
  });

  factory DpsCalculationResult.zero({
    required double monthlyInstallment,
    required int    tenureMonths,
    required double annualInterestRate,
  }) {
    return DpsCalculationResult(
      monthlyInstallment:    monthlyInstallment,
      tenureMonths:          tenureMonths,
      annualInterestRate:    annualInterestRate,
      totalDeposit:          0,
      interestEarned:        0,
      maturityAmount:        0,
      effectiveAnnualYield:  0,
      projectedMaturityDate: DateTime.now(),
    );
  }

  /// Interest as a percentage of total deposit.
  double get interestPercent =>
      totalDeposit > 0 ? (interestEarned / totalDeposit) * 100 : 0;

  @override
  String toString() =>
      'DpsCalculationResult(monthly: $monthlyInstallment, '
      'tenure: $tenureMonths mo, rate: $annualInterestRate%, '
      'deposit: $totalDeposit, maturity: $maturityAmount)';
}
