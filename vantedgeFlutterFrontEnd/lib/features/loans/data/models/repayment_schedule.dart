import 'loan_enums.dart';

/// Maps to [RepaymentScheduleResponseDTO].
///
/// Represents a single installment in a loan repayment schedule.
class RepaymentScheduleModel {
  final int installmentNumber;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final double principalAmount;
  final double interestAmount;
  final double totalAmount;
  final ScheduleStatus status;
  final double? balanceAfterPayment;
  final double? penaltyApplied;

  const RepaymentScheduleModel({
    required this.installmentNumber,
    required this.dueDate,
    this.paymentDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    required this.status,
    this.balanceAfterPayment,
    this.penaltyApplied,
  });

  factory RepaymentScheduleModel.fromJson(Map<String, dynamic> json) {
    return RepaymentScheduleModel(
      installmentNumber: json['installmentNumber'] as int,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'] as String)
          : null,
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestAmount: (json['interestAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: ScheduleStatus.fromString(json['status'] as String),
      balanceAfterPayment: (json['balanceAfterPayment'] as num?)?.toDouble(),
      penaltyApplied: (json['penaltyApplied'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'installmentNumber': installmentNumber,
      'dueDate': dueDate.toIso8601String().split('T').first,
      if (paymentDate != null)
        'paymentDate': paymentDate!.toIso8601String().split('T').first,
      'principalAmount': principalAmount,
      'interestAmount': interestAmount,
      'totalAmount': totalAmount,
      'status': status.toApiString(),
      if (balanceAfterPayment != null)
        'balanceAfterPayment': balanceAfterPayment,
      if (penaltyApplied != null) 'penaltyApplied': penaltyApplied,
    };
  }

  /// Convenience: whether this installment has a penalty.
  bool get hasPenalty => (penaltyApplied ?? 0.0) > 0.0;

  /// Convenience: whether this installment is overdue (past due date and not
  /// yet paid).
  bool get isOverdue =>
      status == ScheduleStatus.overdue ||
      (!status.isPaid && dueDate.isBefore(DateTime.now()));

  @override
  String toString() =>
      'RepaymentScheduleModel(#$installmentNumber, due: ${dueDate.toIso8601String().split("T").first}, '
      'status: ${status.displayName}, total: $totalAmount)';
}

// ---------------------------------------------------------------------------

/// Maps to [DisbursementHistoryDTO].
///
/// Represents a single disbursement event for a loan.
class DisbursementHistoryModel {
  final DateTime? disbursementDate;
  final double? amount;
  final String? transactionId;
  final DisbursementStatus? status;
  final String? reference;

  const DisbursementHistoryModel({
    this.disbursementDate,
    this.amount,
    this.transactionId,
    this.status,
    this.reference,
  });

  factory DisbursementHistoryModel.fromJson(Map<String, dynamic> json) {
    return DisbursementHistoryModel(
      disbursementDate: json['disbursementDate'] != null
          ? DateTime.tryParse(json['disbursementDate'] as String)
          : null,
      amount: (json['amount'] as num?)?.toDouble(),
      transactionId: json['transactionId'] as String?,
      status: json['status'] != null
          ? DisbursementStatus.fromString(json['status'] as String)
          : null,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (disbursementDate != null)
        'disbursementDate':
            disbursementDate!.toIso8601String().split('T').first,
      if (amount != null) 'amount': amount,
      if (transactionId != null) 'transactionId': transactionId,
      if (status != null) 'status': status!.toApiString(),
      if (reference != null) 'reference': reference,
    };
  }

  @override
  String toString() =>
      'DisbursementHistoryModel(date: ${disbursementDate?.toIso8601String().split("T").first}, '
      'amount: $amount, status: ${status?.displayName})';
}
