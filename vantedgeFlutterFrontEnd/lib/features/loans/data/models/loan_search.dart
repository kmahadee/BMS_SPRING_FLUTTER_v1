import 'loan_enums.dart';
import 'loan_model.dart';

/// Maps to [LoanSearchRequestDTO].
///
/// All fields are optional — send only the filters you need.
/// Defaults: [pageNumber] = 0, [pageSize] = 20.
class LoanSearchRequestModel {
  final String? customerId;
  final LoanStatus? loanStatus;
  final LoanType? loanType;

  /// Minimum: 0 (default: 0).
  final int pageNumber;

  /// Minimum: 1 | Maximum: 100 (default: 20).
  final int pageSize;

  const LoanSearchRequestModel({
    this.customerId,
    this.loanStatus,
    this.loanType,
    this.pageNumber = 0,
    this.pageSize = 20,
  });

  factory LoanSearchRequestModel.fromJson(Map<String, dynamic> json) {
    return LoanSearchRequestModel(
      customerId: json['customerId'] as String?,
      loanStatus: json['loanStatus'] != null
          ? LoanStatus.fromString(json['loanStatus'] as String)
          : null,
      loanType: json['loanType'] != null
          ? LoanType.fromString(json['loanType'] as String)
          : null,
      pageNumber: json['pageNumber'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (customerId != null) 'customerId': customerId,
      if (loanStatus != null) 'loanStatus': loanStatus!.toApiString(),
      if (loanType != null) 'loanType': loanType!.toApiString(),
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
  }

  LoanSearchRequestModel copyWith({
    String? customerId,
    LoanStatus? loanStatus,
    LoanType? loanType,
    int? pageNumber,
    int? pageSize,
  }) {
    return LoanSearchRequestModel(
      customerId: customerId ?? this.customerId,
      loanStatus: loanStatus ?? this.loanStatus,
      loanType: loanType ?? this.loanType,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  String toString() =>
      'LoanSearchRequestModel(customerId: $customerId, status: ${loanStatus?.displayName}, '
      'type: ${loanType?.displayName}, page: $pageNumber/$pageSize)';
}

// ---------------------------------------------------------------------------

/// Maps to [LoanSearchResponseDTO].
///
/// Contains a paginated list of [LoanListItemModel] results.
class LoanSearchResponseModel {
  final List<LoanListItemModel> loans;
  final int? totalCount;
  final int? pageNumber;
  final int? pageSize;
  final int? totalPages;

  const LoanSearchResponseModel({
    required this.loans,
    this.totalCount,
    this.pageNumber,
    this.pageSize,
    this.totalPages,
  });

  factory LoanSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final loanList = (json['loans'] as List<dynamic>?)
            ?.map((e) => LoanListItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return LoanSearchResponseModel(
      loans: loanList,
      totalCount: json['totalCount'] as int?,
      pageNumber: json['pageNumber'] as int?,
      pageSize: json['pageSize'] as int?,
      totalPages: json['totalPages'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loans': loans.map((l) => l.toJson()).toList(),
      if (totalCount != null) 'totalCount': totalCount,
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (pageSize != null) 'pageSize': pageSize,
      if (totalPages != null) 'totalPages': totalPages,
    };
  }

  // ── Pagination helpers ───────────────────────────────────────────────────

  bool get hasNextPage =>
      totalPages != null && pageNumber != null && pageNumber! < totalPages! - 1;

  bool get hasPreviousPage => pageNumber != null && pageNumber! > 0;

  bool get isEmpty => loans.isEmpty;

  bool get isNotEmpty => loans.isNotEmpty;

  @override
  String toString() =>
      'LoanSearchResponseModel(count: ${loans.length}, total: $totalCount, '
      'page: $pageNumber of $totalPages)';
}
