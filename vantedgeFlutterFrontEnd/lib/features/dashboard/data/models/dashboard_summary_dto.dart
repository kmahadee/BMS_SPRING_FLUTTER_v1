import 'package:vantedge/features/accounts/data/models/transaction_dto.dart';
// import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
/// Data Transfer Object for dashboard summary information
/// 
/// Contains aggregated data for dashboard display including account summaries,
/// recent transactions, alerts, and upcoming payments.
class DashboardSummaryDTO {
  /// Summary of all accounts
  final AccountsSummary accountsSummary;
  
  /// List of recent transactions (typically last 5-10)
  final List<TransactionDTO> recentTransactions;
  
  /// List of alerts and notifications
  final List<AlertItem> alerts;
  
  /// List of upcoming payments (EMI, DPS, bills)
  final List<UpcomingPayment> upcomingPayments;
  
  /// Total available balance across all accounts
  final double? totalAvailableBalance;
  
  /// Total current balance across all accounts
  final double? totalCurrentBalance;
  
  /// Number of active accounts
  final int? activeAccountsCount;
  
  /// Number of pending approvals (for managers/officers)
  final int? pendingApprovalsCount;
  
  /// Date when summary was generated
  final DateTime generatedDate;

  const DashboardSummaryDTO({
    required this.accountsSummary,
    required this.recentTransactions,
    required this.alerts,
    required this.upcomingPayments,
    this.totalAvailableBalance,
    this.totalCurrentBalance,
    this.activeAccountsCount,
    this.pendingApprovalsCount,
    required this.generatedDate,
  });

  /// Create DashboardSummaryDTO from JSON map
  factory DashboardSummaryDTO.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryDTO(
      accountsSummary: AccountsSummary.fromJson(
        json['accountsSummary'] as Map<String, dynamic>? ?? {},
      ),
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) => TransactionDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      upcomingPayments: (json['upcomingPayments'] as List<dynamic>?)
              ?.map((e) => UpcomingPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAvailableBalance: json['totalAvailableBalance'] != null
          ? (json['totalAvailableBalance'] as num).toDouble()
          : null,
      totalCurrentBalance: json['totalCurrentBalance'] != null
          ? (json['totalCurrentBalance'] as num).toDouble()
          : null,
      activeAccountsCount: json['activeAccountsCount'] as int?,
      pendingApprovalsCount: json['pendingApprovalsCount'] as int?,
      generatedDate: json['generatedDate'] != null
          ? DateTime.parse(json['generatedDate'] as String)
          : DateTime.now(),
    );
  }

  /// Convert DashboardSummaryDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'accountsSummary': accountsSummary.toJson(),
      'recentTransactions': recentTransactions.map((t) => t.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'upcomingPayments': upcomingPayments.map((p) => p.toJson()).toList(),
      if (totalAvailableBalance != null) 'totalAvailableBalance': totalAvailableBalance,
      if (totalCurrentBalance != null) 'totalCurrentBalance': totalCurrentBalance,
      if (activeAccountsCount != null) 'activeAccountsCount': activeAccountsCount,
      if (pendingApprovalsCount != null) 'pendingApprovalsCount': pendingApprovalsCount,
      'generatedDate': generatedDate.toIso8601String(),
    };
  }

  /// Check if there are any unread alerts
  bool get hasUnreadAlerts {
    return alerts.any((alert) => !alert.isRead);
  }

  /// Get count of unread alerts
  int get unreadAlertsCount {
    return alerts.where((alert) => !alert.isRead).length;
  }

  /// Get high priority alerts
  List<AlertItem> get highPriorityAlerts {
    return alerts.where((alert) => alert.priority == 'HIGH').toList();
  }

  /// Get upcoming payments within next 7 days
  List<UpcomingPayment> get upcomingSoon {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return upcomingPayments.where((payment) {
      return payment.dueDate.isAfter(now) && payment.dueDate.isBefore(sevenDaysLater);
    }).toList();
  }
}

/// Summary of accounts grouped by type
class AccountsSummary {
  /// Total number of accounts
  final int totalAccounts;
  
  /// Number of savings accounts
  final int savingsAccounts;
  
  /// Number of current accounts
  final int currentAccounts;
  
  /// Number of salary accounts
  final int salaryAccounts;
  
  /// Number of FD accounts
  final int fdAccounts;
  
  /// Total balance in savings accounts
  final double? savingsBalance;
  
  /// Total balance in current accounts
  final double? currentBalance;
  
  /// Total balance in FD accounts
  final double? fdBalance;

  const AccountsSummary({
    this.totalAccounts = 0,
    this.savingsAccounts = 0,
    this.currentAccounts = 0,
    this.salaryAccounts = 0,
    this.fdAccounts = 0,
    this.savingsBalance,
    this.currentBalance,
    this.fdBalance,
  });

  factory AccountsSummary.fromJson(Map<String, dynamic> json) {
    return AccountsSummary(
      totalAccounts: json['totalAccounts'] as int? ?? 0,
      savingsAccounts: json['savingsAccounts'] as int? ?? 0,
      currentAccounts: json['currentAccounts'] as int? ?? 0,
      salaryAccounts: json['salaryAccounts'] as int? ?? 0,
      fdAccounts: json['fdAccounts'] as int? ?? 0,
      savingsBalance: json['savingsBalance'] != null
          ? (json['savingsBalance'] as num).toDouble()
          : null,
      currentBalance: json['currentBalance'] != null
          ? (json['currentBalance'] as num).toDouble()
          : null,
      fdBalance: json['fdBalance'] != null
          ? (json['fdBalance'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAccounts': totalAccounts,
      'savingsAccounts': savingsAccounts,
      'currentAccounts': currentAccounts,
      'salaryAccounts': salaryAccounts,
      'fdAccounts': fdAccounts,
      if (savingsBalance != null) 'savingsBalance': savingsBalance,
      if (currentBalance != null) 'currentBalance': currentBalance,
      if (fdBalance != null) 'fdBalance': fdBalance,
    };
  }
}

/// Represents an alert or notification item
class AlertItem {
  /// Unique alert ID
  final String id;
  
  /// Alert title
  final String title;
  
  /// Alert message/description
  final String message;
  
  /// Alert type (INFO, WARNING, ERROR, SUCCESS)
  final String type;
  
  /// Priority level (LOW, MEDIUM, HIGH)
  final String priority;
  
  /// Whether alert has been read
  final bool isRead;
  
  /// Date when alert was created
  final DateTime createdDate;
  
  /// Optional action route
  final String? actionRoute;
  
  /// Optional action label
  final String? actionLabel;

  const AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = 'MEDIUM',
    this.isRead = false,
    required this.createdDate,
    this.actionRoute,
    this.actionLabel,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      priority: json['priority'] as String? ?? 'MEDIUM',
      isRead: json['isRead'] as bool? ?? false,
      createdDate: DateTime.parse(json['createdDate'] as String),
      actionRoute: json['actionRoute'] as String?,
      actionLabel: json['actionLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'isRead': isRead,
      'createdDate': createdDate.toIso8601String(),
      if (actionRoute != null) 'actionRoute': actionRoute,
      if (actionLabel != null) 'actionLabel': actionLabel,
    };
  }
}

/// Represents an upcoming payment (EMI, DPS, bill)
class UpcomingPayment {
  /// Unique payment ID
  final String id;
  
  /// Payment type (EMI, DPS, BILL, etc.)
  final String paymentType;
  
  /// Payment description
  final String description;
  
  /// Amount to be paid
  final double amount;
  
  /// Due date
  final DateTime dueDate;
  
  /// Account from which payment will be deducted
  final String? accountNumber;
  
  /// Whether payment is auto-debit enabled
  final bool isAutoDebit;
  
  /// Status (UPCOMING, DUE, OVERDUE)
  final String status;

  const UpcomingPayment({
    required this.id,
    required this.paymentType,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.accountNumber,
    this.isAutoDebit = false,
    this.status = 'UPCOMING',
  });

  factory UpcomingPayment.fromJson(Map<String, dynamic> json) {
    return UpcomingPayment(
      id: json['id'] as String,
      paymentType: json['paymentType'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      accountNumber: json['accountNumber'] as String?,
      isAutoDebit: json['isAutoDebit'] as bool? ?? false,
      status: json['status'] as String? ?? 'UPCOMING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentType': paymentType,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      if (accountNumber != null) 'accountNumber': accountNumber,
      'isAutoDebit': isAutoDebit,
      'status': status,
    };
  }

  /// Get days until due
  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  /// Check if payment is overdue
  bool get isOverdue {
    return dueDate.isBefore(DateTime.now()) && status != 'PAID';
  }

  /// Check if payment is due soon (within 3 days)
  bool get isDueSoon {
    return daysUntilDue >= 0 && daysUntilDue <= 3;
  }
}