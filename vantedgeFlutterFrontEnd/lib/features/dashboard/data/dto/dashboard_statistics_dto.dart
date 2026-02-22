/// DTO for dashboard statistics
class DashboardStatisticsDTO {
  final int? totalAccounts;
  final int? totalCustomers;
  final int? totalUsers;
  final int? activeBranches;
  final int? activeStaff;
  final int? todayTransactions;
  final int? pendingApprovals;
  final double? totalDeposits;
  final double? totalWithdrawals;
  final double? transactionVolume;
  final int? activeLoans;
  final int? activeCards;

  DashboardStatisticsDTO({
    this.totalAccounts,
    this.totalCustomers,
    this.totalUsers,
    this.activeBranches,
    this.activeStaff,
    this.todayTransactions,
    this.pendingApprovals,
    this.totalDeposits,
    this.totalWithdrawals,
    this.transactionVolume,
    this.activeLoans,
    this.activeCards,
  });

  factory DashboardStatisticsDTO.fromJson(Map<String, dynamic> json) {
    return DashboardStatisticsDTO(
      totalAccounts: json['totalAccounts'] as int?,
      totalCustomers: json['totalCustomers'] as int?,
      totalUsers: json['totalUsers'] as int?,
      activeBranches: json['activeBranches'] as int?,
      activeStaff: json['activeStaff'] as int?,
      todayTransactions: json['todayTransactions'] as int?,
      pendingApprovals: json['pendingApprovals'] as int?,
      totalDeposits: (json['totalDeposits'] as num?)?.toDouble(),
      totalWithdrawals: (json['totalWithdrawals'] as num?)?.toDouble(),
      transactionVolume: (json['transactionVolume'] as num?)?.toDouble(),
      activeLoans: json['activeLoans'] as int?,
      activeCards: json['activeCards'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAccounts': totalAccounts,
      'totalCustomers': totalCustomers,
      'totalUsers': totalUsers,
      'activeBranches': activeBranches,
      'activeStaff': activeStaff,
      'todayTransactions': todayTransactions,
      'pendingApprovals': pendingApprovals,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'transactionVolume': transactionVolume,
      'activeLoans': activeLoans,
      'activeCards': activeCards,
    };
  }
}

/// DTO for recent transactions
class RecentTransactionDTO {
  final int id;
  final String type;
  final double amount;
  final DateTime timestamp;
  final String? description;
  final String? fromAccount;
  final String? toAccount;
  final String status;

  RecentTransactionDTO({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.description,
    this.fromAccount,
    this.toAccount,
    required this.status,
  });

  factory RecentTransactionDTO.fromJson(Map<String, dynamic> json) {
    return RecentTransactionDTO(
      id: json['id'] as int,
      type: json['type'] as String? ?? json['transactionType'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String? ?? 
                                 json['transactionDate'] as String? ??
                                 json['createdAt'] as String),
      description: json['description'] as String?,
      fromAccount: json['fromAccount'] as String? ?? json['fromAccountNumber'] as String?,
      toAccount: json['toAccount'] as String? ?? json['toAccountNumber'] as String?,
      status: json['status'] as String? ?? 'COMPLETED',
    );
  }

  bool get isCredit {
    return type.toUpperCase().contains('DEPOSIT') || 
           type.toUpperCase().contains('CREDIT') ||
           type.toUpperCase().contains('RECEIVE');
  }

  bool get isDebit {
    return type.toUpperCase().contains('WITHDRAWAL') || 
           type.toUpperCase().contains('DEBIT') ||
           type.toUpperCase().contains('TRANSFER') ||
           type.toUpperCase().contains('PAYMENT');
  }
}