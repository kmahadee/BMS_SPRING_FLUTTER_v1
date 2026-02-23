import 'loan_enums.dart';
import 'loan_model.dart';
import 'repayment_schedule.dart';


class LoanStatementModel {
  final String loanId;
  final String? customerName;
  final String? customerEmail;
  final LoanType loanType;
  final double principal;
  final double annualInterestRate;
  final int tenureMonths;
  final double? monthlyEMI;
  final DateTime? applicationDate;
  final DateTime? disbursementDate;
  final double? totalAmount;
  final double? totalPaid;
  final double? outstandingBalance;
  final int? installmentsPaid;
  final int? installmentsPending;
  final DateTime? nextEMIDate;
  final double? nextEMIAmount;

  /// Full repayment schedule (maps to [repaymentSchedule] JSON key).
  final List<RepaymentScheduleModel> repaymentSchedule;

  /// Disbursement history (maps to [disbursementHistory] JSON key).
  final List<DisbursementHistoryModel> disbursementHistory;

  /// The full loan response embedded in the statement (maps to [loan] JSON key).
  final LoanResponseModel? loan;

  const LoanStatementModel({
    required this.loanId,
    this.customerName,
    this.customerEmail,
    required this.loanType,
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    this.monthlyEMI,
    this.applicationDate,
    this.disbursementDate,
    this.totalAmount,
    this.totalPaid,
    this.outstandingBalance,
    this.installmentsPaid,
    this.installmentsPending,
    this.nextEMIDate,
    this.nextEMIAmount,
    this.repaymentSchedule = const [],
    this.disbursementHistory = const [],
    this.loan,
  });

  factory LoanStatementModel.fromJson(Map<String, dynamic> json) {
    // Parse repayment schedule list.
    final scheduleList = (json['repaymentSchedule'] as List<dynamic>?)
            ?.map((e) =>
                RepaymentScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse disbursement history list.
    final disbursementList = (json['disbursementHistory'] as List<dynamic>?)
            ?.map((e) =>
                DisbursementHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse the embedded loan object if present.
    LoanResponseModel? loanModel;
    if (json['loan'] != null) {
      loanModel = LoanResponseModel.fromJson(json['loan'] as Map<String, dynamic>);
    }

    return LoanStatementModel(
      loanId: json['loanId'] as String,
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
      loanType: LoanType.fromString(json['loanType'] as String),
      principal: (json['principal'] as num).toDouble(),
      annualInterestRate: (json['annualInterestRate'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      monthlyEMI: (json['monthlyEMI'] as num?)?.toDouble(),
      applicationDate: json['applicationDate'] != null
          ? DateTime.tryParse(json['applicationDate'] as String)
          : null,
      disbursementDate: json['disbursementDate'] != null
          ? DateTime.tryParse(json['disbursementDate'] as String)
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      totalPaid: (json['totalPaid'] as num?)?.toDouble(),
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble(),
      installmentsPaid: json['installmentsPaid'] as int?,
      installmentsPending: json['installmentsPending'] as int?,
      nextEMIDate: json['nextEMIDate'] != null
          ? DateTime.tryParse(json['nextEMIDate'] as String)
          : null,
      nextEMIAmount: (json['nextEMIAmount'] as num?)?.toDouble(),
      repaymentSchedule: scheduleList,
      disbursementHistory: disbursementList,
      loan: loanModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      if (customerName != null) 'customerName': customerName,
      if (customerEmail != null) 'customerEmail': customerEmail,
      'loanType': loanType.toApiString(),
      'principal': principal,
      'annualInterestRate': annualInterestRate,
      'tenureMonths': tenureMonths,
      if (monthlyEMI != null) 'monthlyEMI': monthlyEMI,
      if (applicationDate != null)
        'applicationDate': applicationDate!.toIso8601String().split('T').first,
      if (disbursementDate != null)
        'disbursementDate': disbursementDate!.toIso8601String().split('T').first,
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (totalPaid != null) 'totalPaid': totalPaid,
      if (outstandingBalance != null) 'outstandingBalance': outstandingBalance,
      if (installmentsPaid != null) 'installmentsPaid': installmentsPaid,
      if (installmentsPending != null) 'installmentsPending': installmentsPending,
      if (nextEMIDate != null)
        'nextEMIDate': nextEMIDate!.toIso8601String().split('T').first,
      if (nextEMIAmount != null) 'nextEMIAmount': nextEMIAmount,
      'repaymentSchedule': repaymentSchedule.map((s) => s.toJson()).toList(),
      'disbursementHistory': disbursementHistory.map((d) => d.toJson()).toList(),
      if (loan != null) 'loan': loan!.toJson(),
    };
  }

  // ── Derived helpers ──────────────────────────────────────────────────────

  /// Total number of installments in the schedule.
  int get totalInstallments => repaymentSchedule.length;

  /// Installments that are overdue (not yet paid and past due date).
  List<RepaymentScheduleModel> get overdueInstallments =>
      repaymentSchedule.where((s) => s.isOverdue).toList();

  /// Installments that are pending (not yet paid and not overdue).
  List<RepaymentScheduleModel> get pendingInstallments => repaymentSchedule
      .where((s) => !s.status.isPaid && !s.isOverdue)
      .toList();

  /// Total penalty amount across all installments.
  double get totalPenalty => repaymentSchedule.fold(
        0.0,
        (sum, s) => sum + (s.penaltyApplied ?? 0.0),
      );

  @override
  String toString() =>
      'LoanStatementModel(loanId: $loanId, type: ${loanType.displayName}, '
      'paid: $installmentsPaid/${totalInstallments}, outstanding: $outstandingBalance)';
}
