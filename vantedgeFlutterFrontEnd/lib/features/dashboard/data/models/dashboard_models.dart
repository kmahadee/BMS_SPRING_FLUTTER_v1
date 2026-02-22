/// Account data from API
class AccountListItem {
  final int id;
  final String accountNumber;
  final String? customerId;
  final String? customerName;
  final String accountType;
  final int? branchId;
  final String? branchCode;
  final String? branchName;
  final double balance;
  final String status;

  AccountListItem({
    required this.id,
    required this.accountNumber,
    this.customerId,
    this.customerName,
    required this.accountType,
    this.branchId,
    this.branchCode,
    this.branchName,
    required this.balance,
    required this.status,
  });

  factory AccountListItem.fromJson(Map<String, dynamic> json) {
    return AccountListItem(
      id: json['id'] as int,
      accountNumber: json['accountNumber'] as String,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      accountType: json['accountType'] as String,
      branchId: json['branchId'] as int?,
      branchCode: json['branchCode'] as String?,
      branchName: json['branchName'] as String?,
      balance: (json['balance'] as num).toDouble(),
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

/// Loan data from API
class LoanListItem {
  final String loanId;
  final String loanType;
  final String loanStatus;
  final String approvalStatus;
  final double principal;
  final double outstandingBalance;
  final double monthlyEMI;
  final DateTime applicationDate;
  final String? customerName;
  final String? customerId;

  LoanListItem({
    required this.loanId,
    required this.loanType,
    required this.loanStatus,
    required this.approvalStatus,
    required this.principal,
    required this.outstandingBalance,
    required this.monthlyEMI,
    required this.applicationDate,
    this.customerName,
    this.customerId,
  });

  factory LoanListItem.fromJson(Map<String, dynamic> json) {
    return LoanListItem(
      loanId: json['loanId'] as String,
      loanType: json['loanType'] as String,
      loanStatus: json['loanStatus'] as String,
      approvalStatus: json['approvalStatus'] as String,
      principal: (json['principal'] as num).toDouble(),
      outstandingBalance: (json['outstandingBalance'] as num).toDouble(),
      monthlyEMI: (json['monthlyEMI'] as num).toDouble(),
      applicationDate: DateTime.parse(json['applicationDate'] as String),
      customerName: json['customerName'] as String?,
      customerId: json['customerId'] as String?,
    );
  }

  bool get isPending => approvalStatus.toUpperCase() == 'PENDING';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => approvalStatus.toUpperCase() == 'REJECTED';
  bool get isDisbursed => loanStatus.toUpperCase() == 'DISBURSED' || loanStatus.toUpperCase() == 'ACTIVE';
}

/// Card data from API
class CardListItem {
  final int id;
  final String maskedCardNumber;
  final String cardHolderName;
  final String cardType;
  final String status;
  final DateTime expiryDate;
  final double creditLimit;
  final double availableLimit;
  final String? customerId;

  CardListItem({
    required this.id,
    required this.maskedCardNumber,
    required this.cardHolderName,
    required this.cardType,
    required this.status,
    required this.expiryDate,
    required this.creditLimit,
    required this.availableLimit,
    this.customerId,
  });

  factory CardListItem.fromJson(Map<String, dynamic> json) {
    return CardListItem(
      id: json['id'] as int,
      maskedCardNumber: json['maskedCardNumber'] as String,
      cardHolderName: json['cardHolderName'] as String,
      cardType: json['cardType'] as String,
      status: json['status'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      creditLimit: (json['creditLimit'] as num).toDouble(),
      availableLimit: (json['availableLimit'] as num).toDouble(),
      customerId: json['customerId'] as String?,
    );
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isBlocked => status.toUpperCase() == 'BLOCKED';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';
}

/// Statistics calculated locally from API data
class DashboardStatistics {
  // Account statistics
  final int totalAccounts;
  final int activeAccounts;
  final double totalDeposits;

  // Customer statistics
  final int? totalCustomers;

  // Loan statistics
  final int? totalLoans;
  final int? pendingLoans;
  final int? approvedLoans;
  final int? disbursedLoans;
  final double? totalLoanAmount;
  final double? totalOutstanding;

  // Card statistics
  final int? totalCards;
  final int? pendingCards;
  final int? activeCards;
  final int? blockedCards;
  final double? totalCreditLimit;

  // Branch statistics
  final int? totalBranches;
  final int? activeBranches;

  DashboardStatistics({
    required this.totalAccounts,
    required this.activeAccounts,
    required this.totalDeposits,
    this.totalCustomers,
    this.totalLoans,
    this.pendingLoans,
    this.approvedLoans,
    this.disbursedLoans,
    this.totalLoanAmount,
    this.totalOutstanding,
    this.totalCards,
    this.pendingCards,
    this.activeCards,
    this.blockedCards,
    this.totalCreditLimit,
    this.totalBranches,
    this.activeBranches,
  });

  factory DashboardStatistics.fromBankData(Map<String, dynamic> data) {
    return DashboardStatistics(
      totalAccounts: data['totalAccounts'] as int? ?? 0,
      activeAccounts: data['activeAccounts'] as int? ?? 0,
      totalDeposits: (data['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      totalCustomers: data['totalCustomers'] as int?,
      totalLoans: data['activeLoans'] as int?,
      totalLoanAmount: (data['totalLoanAmount'] as num?)?.toDouble(),
      totalCards: data['activeCards'] as int?,
      totalBranches: data['totalBranches'] as int?,
      activeBranches: data['activeBranches'] as int?,
    );
  }

  factory DashboardStatistics.fromBranchData(Map<String, dynamic> data) {
    return DashboardStatistics(
      totalAccounts: data['totalAccounts'] as int? ?? 0,
      activeAccounts: data['activeAccounts'] as int? ?? 0,
      totalDeposits: (data['totalDeposits'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory DashboardStatistics.fromLoanData(Map<String, dynamic> data) {
    return DashboardStatistics(
      totalAccounts: 0,
      activeAccounts: 0,
      totalDeposits: 0.0,
      totalLoans: data['totalLoans'] as int?,
      pendingLoans: data['pending'] as int?,
      approvedLoans: data['approved'] as int?,
      disbursedLoans: data['disbursed'] as int?,
      totalLoanAmount: (data['totalDisbursed'] as num?)?.toDouble(),
      totalOutstanding: (data['totalOutstanding'] as num?)?.toDouble(),
    );
  }

  factory DashboardStatistics.fromCardData(Map<String, dynamic> data) {
    return DashboardStatistics(
      totalAccounts: 0,
      activeAccounts: 0,
      totalDeposits: 0.0,
      totalCards: data['totalCards'] as int?,
      pendingCards: data['pending'] as int?,
      activeCards: data['active'] as int?,
      blockedCards: data['blocked'] as int?,
      totalCreditLimit: (data['totalCreditLimit'] as num?)?.toDouble(),
    );
  }
}