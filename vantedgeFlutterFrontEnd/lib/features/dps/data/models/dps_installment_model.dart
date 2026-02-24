class DpsInstallmentModel {
  final int? installmentNumber;
  final DateTime? dueDate;
  final DateTime? paymentDate;
  final double? amount;
  final double? penaltyAmount;
  final String? status;
  final String? transactionId;
  final String? receiptNumber;

  const DpsInstallmentModel({
    this.installmentNumber,
    this.dueDate,
    this.paymentDate,
    this.amount,
    this.penaltyAmount,
    this.status,
    this.transactionId,
    this.receiptNumber,
  });

  factory DpsInstallmentModel.fromJson(Map<String, dynamic> json) {
    return DpsInstallmentModel(
      installmentNumber: json['installmentNumber'] as int?,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'] as String)
          : null,
      amount: (json['amount'] as num?)?.toDouble(),
      penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      transactionId: json['transactionId'] as String?,
      receiptNumber: json['receiptNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (installmentNumber != null) 'installmentNumber': installmentNumber,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String().split('T').first,
      if (paymentDate != null) 'paymentDate': paymentDate!.toIso8601String().split('T').first,
      if (amount != null) 'amount': amount,
      if (penaltyAmount != null) 'penaltyAmount': penaltyAmount,
      if (status != null) 'status': status,
      if (transactionId != null) 'transactionId': transactionId,
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
    };
  }
}
