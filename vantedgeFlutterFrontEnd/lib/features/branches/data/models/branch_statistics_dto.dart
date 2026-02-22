/// Data Transfer Object for branch statistics
/// 
/// Contains aggregate statistics and metrics for a specific branch,
/// useful for branch managers and administrators.
class BranchStatisticsDTO {
  /// Branch ID these statistics belong to
  final int branchId;
  
  /// Total number of accounts managed by this branch
  final int totalAccounts;
  
  /// Total number of customers served by this branch
  final int totalCustomers;
  
  /// Total deposits held by this branch
  final double totalDeposits;
  
  /// Total loans disbursed by this branch
  final double totalLoans;
  
  /// Number of active accounts
  final int? activeAccounts;
  
  /// Number of inactive/dormant accounts
  final int? inactiveAccounts;
  
  /// Number of active loans
  final int? activeLoans;
  
  /// Number of cards issued by this branch
  final int? totalCards;
  
  /// Number of transactions processed today
  final int? todayTransactions;
  
  /// Total transaction volume today
  final double? todayVolume;
  
  /// Number of pending approvals
  final int? pendingApprovals;
  
  /// Date when statistics were generated
  final DateTime? generatedDate;

  const BranchStatisticsDTO({
    required this.branchId,
    required this.totalAccounts,
    required this.totalCustomers,
    required this.totalDeposits,
    required this.totalLoans,
    this.activeAccounts,
    this.inactiveAccounts,
    this.activeLoans,
    this.totalCards,
    this.todayTransactions,
    this.todayVolume,
    this.pendingApprovals,
    this.generatedDate,
  });

  /// Create BranchStatisticsDTO from JSON map
  factory BranchStatisticsDTO.fromJson(Map<String, dynamic> json) {
    return BranchStatisticsDTO(
      branchId: json['branchId'] as int,
      totalAccounts: json['totalAccounts'] as int? ?? 0,
      totalCustomers: json['totalCustomers'] as int? ?? 0,
      totalDeposits: (json['totalDeposits'] ?? 0).toDouble(),
      totalLoans: (json['totalLoans'] ?? 0).toDouble(),
      activeAccounts: json['activeAccounts'] as int?,
      inactiveAccounts: json['inactiveAccounts'] as int?,
      activeLoans: json['activeLoans'] as int?,
      totalCards: json['totalCards'] as int?,
      todayTransactions: json['todayTransactions'] as int?,
      todayVolume: json['todayVolume'] != null 
          ? (json['todayVolume'] as num).toDouble() 
          : null,
      pendingApprovals: json['pendingApprovals'] as int?,
      generatedDate: json['generatedDate'] != null
          ? DateTime.parse(json['generatedDate'] as String)
          : null,
    );
  }

  /// Convert BranchStatisticsDTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'totalAccounts': totalAccounts,
      'totalCustomers': totalCustomers,
      'totalDeposits': totalDeposits,
      'totalLoans': totalLoans,
      if (activeAccounts != null) 'activeAccounts': activeAccounts,
      if (inactiveAccounts != null) 'inactiveAccounts': inactiveAccounts,
      if (activeLoans != null) 'activeLoans': activeLoans,
      if (totalCards != null) 'totalCards': totalCards,
      if (todayTransactions != null) 'todayTransactions': todayTransactions,
      if (todayVolume != null) 'todayVolume': todayVolume,
      if (pendingApprovals != null) 'pendingApprovals': pendingApprovals,
      if (generatedDate != null) 'generatedDate': generatedDate!.toIso8601String(),
    };
  }

  /// Calculate average deposit per account
  double get averageDepositPerAccount {
    if (totalAccounts == 0) return 0.0;
    return totalDeposits / totalAccounts;
  }

  /// Calculate average loan amount
  double get averageLoanAmount {
    if (activeLoans == null || activeLoans == 0) return 0.0;
    return totalLoans / activeLoans!;
  }

  /// Calculate customer to account ratio
  double get customerAccountRatio {
    if (totalCustomers == 0) return 0.0;
    return totalAccounts / totalCustomers;
  }

  /// Get account activity percentage
  double get accountActivityPercentage {
    if (totalAccounts == 0) return 0.0;
    if (activeAccounts == null) return 0.0;
    return (activeAccounts! / totalAccounts) * 100;
  }

  /// Create a copy with modified fields
  BranchStatisticsDTO copyWith({
    int? branchId,
    int? totalAccounts,
    int? totalCustomers,
    double? totalDeposits,
    double? totalLoans,
    int? activeAccounts,
    int? inactiveAccounts,
    int? activeLoans,
    int? totalCards,
    int? todayTransactions,
    double? todayVolume,
    int? pendingApprovals,
    DateTime? generatedDate,
  }) {
    return BranchStatisticsDTO(
      branchId: branchId ?? this.branchId,
      totalAccounts: totalAccounts ?? this.totalAccounts,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalLoans: totalLoans ?? this.totalLoans,
      activeAccounts: activeAccounts ?? this.activeAccounts,
      inactiveAccounts: inactiveAccounts ?? this.inactiveAccounts,
      activeLoans: activeLoans ?? this.activeLoans,
      totalCards: totalCards ?? this.totalCards,
      todayTransactions: todayTransactions ?? this.todayTransactions,
      todayVolume: todayVolume ?? this.todayVolume,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      generatedDate: generatedDate ?? this.generatedDate,
    );
  }

  @override
  String toString() {
    return 'BranchStatisticsDTO(branchId: $branchId, accounts: $totalAccounts, customers: $totalCustomers, deposits: $totalDeposits)';
  }
}