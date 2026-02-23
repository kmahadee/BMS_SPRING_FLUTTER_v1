import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import '../../data/models/loan_enums.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_application.dart';
import '../../data/models/loan_search.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/loan_repository_impl.dart'; // LoanNotFoundException

/// Staff / loan-officer provider for the Loan Management feature.
///
/// Manages the pending-approval queue, search results, loan detail view, and
/// all mutating staff operations (approve, reject, disburse).
///
/// Follows the same pattern as [AccountProvider] / [TransactionProvider]:
///   - [ChangeNotifier] with guarded [_activeRequests] deduplication.
///   - Typed exception catch ladder.
///   - Private [_setLoading] / [_setError] helpers.
///   - [notifyListeners] called only after state mutation is complete.
class LoanOfficerProvider extends ChangeNotifier {
  final LoanRepository _repository;
  final Logger _logger = Logger();

  // ── State ────────────────────────────────────────────────────────────────

  /// Loans awaiting an approval decision (the officer's work queue).
  List<LoanListItemModel> _pendingLoans = [];

  /// Results from the most recent [searchLoans] / [fetchCustomerLoans] call.
  List<LoanListItemModel> _searchResults = [];

  /// Pagination metadata from the most recent search / getAllLoans call.
  LoanSearchResponseModel? _lastSearchResponse;

  /// The currently viewed loan detail.
  LoanResponseModel? _selectedLoan;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _successMessage;

  /// The last [LoanSearchRequestModel] used — stored so the UI can paginate.
  LoanSearchRequestModel? _lastSearchRequest;

  final Set<String> _activeRequests = {};

  // ── Constructor ──────────────────────────────────────────────────────────

  LoanOfficerProvider({required LoanRepository repository})
      : _repository = repository {
    _logger.i('LoanOfficerProvider initialized');
  }

  // ── Read-only getters ────────────────────────────────────────────────────

  /// Unmodifiable pending-approval work queue.
  List<LoanListItemModel> get pendingLoans => List.unmodifiable(_pendingLoans);

  /// Unmodifiable results of the most recent search.
  List<LoanListItemModel> get searchResults => List.unmodifiable(_searchResults);

  /// Full paginated response object for the most recent search (includes
  /// totalCount, totalPages etc).
  LoanSearchResponseModel? get lastSearchResponse => _lastSearchResponse;

  /// The currently selected loan for the detail / action view.
  LoanResponseModel? get selectedLoan => _selectedLoan;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;

  // ── Computed getters ─────────────────────────────────────────────────────

  bool get hasPendingLoans => _pendingLoans.isNotEmpty;
  int get pendingLoanCount => _pendingLoans.length;

  bool get hasSearchResults => _searchResults.isNotEmpty;

  /// Whether another page is available for the current search.
  bool get hasNextPage => _lastSearchResponse?.hasNextPage ?? false;

  /// Current page index from the last search response.
  int get currentPage => _lastSearchResponse?.pageNumber ?? 0;

  /// Total number of matching loans across all pages.
  int? get totalSearchCount => _lastSearchResponse?.totalCount;

  /// Total outstanding balance across all pending-queue loans.
  double get totalOutstandingPending => _pendingLoans.fold(
        0.0,
        (sum, l) => sum + (l.outstandingBalance ?? 0.0),
      );

  /// Count of pending loans broken down by type (HOME_LOAN → 3, etc.).
  Map<LoanType, int> get pendingByType {
    final map = <LoanType, int>{};
    for (final loan in _pendingLoans) {
      map[loan.loanType] = (map[loan.loanType] ?? 0) + 1;
    }
    return map;
  }

  // ── Public actions ───────────────────────────────────────────────────────

  /// Loads all loans with [ApprovalStatus.pending] into [pendingLoans].
  Future<void> fetchPendingLoans() async {
    const requestId = 'fetchPendingLoans';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching pending-approval loans');

      final loans = await _repository.getPendingApprovalLoans();

      _pendingLoans = loans;
      _setLoading(false);

      _logger.i('Fetched ${loans.length} pending-approval loans');
    } on NetworkException catch (e) {
      _logger.e('Network error fetching pending loans: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised fetching pending loans: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ForbiddenException catch (e) {
      _logger.e('Access denied fetching pending loans: ${e.message}');
      _setError('You do not have permission to view the approval queue.');
      _setLoading(false);
    } on TimeoutException catch (e) {
      _logger.e('Timeout fetching pending loans: ${e.message}');
      _setError('Request timed out. Please try again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching pending loans: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching pending loans: $e');
      _setError('Failed to load pending loans. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Loads full detail for [loanId] and sets it as [selectedLoan].
  Future<void> fetchLoanById(String loanId) async {
    final requestId = 'fetchLoanById_$loanId';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching loan detail: $loanId');

      final loan = await _repository.getLoanById(loanId);

      _selectedLoan = loan;
      _setLoading(false);

      _logger.i('Loan detail fetched: $loanId');
    } on LoanNotFoundException catch (e) {
      _logger.e('Loan not found: $loanId — ${e.message}');
      _setError('Loan not found.');
      _setLoading(false);
    } on ForbiddenException catch (e) {
      _logger.e('Access denied to loan $loanId: ${e.message}');
      _setError('You do not have permission to view this loan.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error fetching loan $loanId: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised fetching loan $loanId: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching loan $loanId: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching loan $loanId: $e');
      _setError('Failed to load loan details. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Approves a loan application.
  ///
  /// [request] carries the loanId, optional comments, approvalConditions,
  /// and interestRateModification. [approvalStatus] is forced to APPROVED
  /// by the repository before sending.
  ///
  /// On success the loan is removed from [pendingLoans] and [selectedLoan]
  /// is updated with the new state. Returns `true` on success.
  Future<bool> approveLoan(LoanApprovalRequestModel request) async {
    final requestId = 'approveLoan_${request.loanId}';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i('Approving loan: ${request.loanId}');

      final updatedLoan = await _repository.approveLoan(
        request.loanId,
        request,
      );

      _removeLoanFromPending(updatedLoan.loanId);
      _selectedLoan = updatedLoan;

      _setSuccess('Loan ${request.loanId} approved successfully.');
      _setLoading(false);

      _logger.i('Loan approved: ${request.loanId}');
      return true;
    } on LoanNotFoundException catch (e) {
      _logger.e('Loan not found for approval ${request.loanId}: ${e.message}');
      _setError('Loan not found. It may have already been processed.');
      _setLoading(false);
      return false;
    } on ForbiddenException catch (e) {
      _logger.e('Access denied approving ${request.loanId}: ${e.message}');
      _setError('You do not have permission to approve this loan.');
      _setLoading(false);
      return false;
    } on BadRequestException catch (e) {
      _logger.e('Bad approval request ${request.loanId}: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on ConflictException catch (e) {
      _logger.e('Conflict approving ${request.loanId}: ${e.message}');
      _setError('This loan has already been processed: ${e.message}');
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error approving ${request.loanId}: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised approving ${request.loanId}: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error approving ${request.loanId}: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error approving ${request.loanId}: $e');
      _setError('Approval failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Rejects a loan application.
  ///
  /// [request] carries loanId, rejectionReason, and optional comments.
  /// On success the loan is removed from [pendingLoans].
  /// Returns `true` on success.
  Future<bool> rejectLoan(LoanApprovalRequestModel request) async {
    final requestId = 'rejectLoan_${request.loanId}';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i('Rejecting loan: ${request.loanId}');

      final updatedLoan = await _repository.rejectLoan(
        request.loanId,
        request,
      );

      _removeLoanFromPending(updatedLoan.loanId);
      _selectedLoan = updatedLoan;

      _setSuccess('Loan ${request.loanId} rejected.');
      _setLoading(false);

      _logger.i('Loan rejected: ${request.loanId}');
      return true;
    } on LoanNotFoundException catch (e) {
      _logger.e('Loan not found for rejection ${request.loanId}: ${e.message}');
      _setError('Loan not found. It may have already been processed.');
      _setLoading(false);
      return false;
    } on ForbiddenException catch (e) {
      _logger.e('Access denied rejecting ${request.loanId}: ${e.message}');
      _setError('You do not have permission to reject this loan.');
      _setLoading(false);
      return false;
    } on BadRequestException catch (e) {
      _logger.e('Bad rejection request ${request.loanId}: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on ConflictException catch (e) {
      _logger.e('Conflict rejecting ${request.loanId}: ${e.message}');
      _setError('This loan has already been processed: ${e.message}');
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error rejecting ${request.loanId}: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised rejecting ${request.loanId}: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error rejecting ${request.loanId}: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error rejecting ${request.loanId}: $e');
      _setError('Rejection failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Disburses an approved loan.
  ///
  /// [request] carries loanId, disbursementAmount, accountNumber, and
  /// optional bankDetails / scheduledDate.
  /// On success [selectedLoan] is updated. Returns `true` on success.
  Future<bool> disburseLoan(LoanDisbursementRequestModel request) async {
    final requestId = 'disburseLoan_${request.loanId}';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i(
        'Disbursing loan: ${request.loanId} — '
        'amount: ${request.disbursementAmount}, '
        'account: ${request.accountNumber}',
      );

      final updatedLoan = await _repository.disburseLoan(
        request.loanId,
        request,
      );

      _selectedLoan = updatedLoan;
      _updateLoanInSearchResults(updatedLoan);

      _setSuccess(
        'Disbursement of ৳${request.disbursementAmount.toStringAsFixed(2)} '
        'for loan ${request.loanId} processed successfully.',
      );
      _setLoading(false);

      _logger.i('Loan disbursed: ${request.loanId}');
      return true;
    } on LoanNotFoundException catch (e) {
      _logger.e(
          'Loan not found for disbursement ${request.loanId}: ${e.message}');
      _setError('Loan not found.');
      _setLoading(false);
      return false;
    } on ForbiddenException catch (e) {
      _logger.e(
          'Access denied for disbursement ${request.loanId}: ${e.message}');
      _setError('You do not have permission to disburse this loan.');
      _setLoading(false);
      return false;
    } on BadRequestException catch (e) {
      _logger.e('Bad disbursement request ${request.loanId}: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on ConflictException catch (e) {
      _logger.e('Conflict disbursing ${request.loanId}: ${e.message}');
      _setError('Disbursement conflict: ${e.message}');
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e(
          'Network error during disbursement ${request.loanId}: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised disbursement ${request.loanId}: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error during disbursement ${request.loanId}: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error during disbursement ${request.loanId}: $e');
      _setError('Disbursement failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Searches loans with optional filters and stores results in [searchResults].
  ///
  /// The full paginated response is stored in [lastSearchResponse] so the UI
  /// can read [hasNextPage], [totalSearchCount], etc.
  Future<void> searchLoans(LoanSearchRequestModel request) async {
    final requestId =
        'searchLoans_${request.loanStatus?.toApiString()}_'
        '${request.loanType?.toApiString()}_'
        '${request.customerId}_'
        '${request.pageNumber}';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i(
        'Searching loans — '
        'status: ${request.loanStatus?.displayName}, '
        'type: ${request.loanType?.displayName}, '
        'customer: ${request.customerId}, '
        'page: ${request.pageNumber}/${request.pageSize}',
      );

      _lastSearchRequest = request;
      final response = await _repository.searchLoans(request);

      // For page > 0 (load-more), append; otherwise replace.
      if (request.pageNumber > 0) {
        _searchResults = [..._searchResults, ...response.loans];
      } else {
        _searchResults = response.loans;
      }
      _lastSearchResponse = response;
      _setLoading(false);

      _logger.i(
        'Search returned ${response.loans.length} loans '
        '(total: ${response.totalCount})',
      );
    } on NetworkException catch (e) {
      _logger.e('Network error searching loans: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on ForbiddenException catch (e) {
      _logger.e('Access denied searching loans: ${e.message}');
      _setError('You do not have permission to search loans.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised searching loans: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on BadRequestException catch (e) {
      _logger.e('Bad search request: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error searching loans: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error searching loans: $e');
      _setError('Search failed. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Loads the next page of results for the current search filter.
  ///
  /// A no-op if [hasNextPage] is `false` or no previous search has been run.
  Future<void> loadNextPage() async {
    if (!hasNextPage || _lastSearchRequest == null) return;

    final nextRequest = _lastSearchRequest!.copyWith(
      pageNumber: currentPage + 1,
    );
    await searchLoans(nextRequest);
  }

  /// Loads all loans for a specific customer into [searchResults].
  ///
  /// Replaces [searchResults] with the fetched list and clears
  /// [lastSearchResponse] since this endpoint is not paginated.
  Future<void> fetchCustomerLoans(String customerId) async {
    final requestId = 'fetchCustomerLoans_$customerId';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching loans for customer: $customerId');

      final loans = await _repository.getLoansByCustomerId(customerId);

      _searchResults = loans;
      _lastSearchResponse = null; // Non-paginated endpoint
      _setLoading(false);

      _logger.i(
        'Fetched ${loans.length} loans for customer: $customerId',
      );
    } on NetworkException catch (e) {
      _logger.e(
          'Network error fetching customer loans $customerId: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on ForbiddenException catch (e) {
      _logger.e(
          'Access denied fetching loans for $customerId: ${e.message}');
      _setError('You do not have permission to view this customer\'s loans.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e(
          'Unauthorised fetching loans for $customerId: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching customer loans $customerId: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching customer loans $customerId: $e');
      _setError('Failed to load customer loans. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  // ── Public UI helpers ─────────────────────────────────────────────────────

  void selectLoan(LoanResponseModel? loan) {
    _logger.d(loan != null
        ? 'Selecting loan: ${loan.loanId}'
        : 'Deselecting loan');
    _selectedLoan = loan;
    notifyListeners();
  }

  void clearSelectedLoan() {
    _logger.d('Clearing selected loan');
    _selectedLoan = null;
    notifyListeners();
  }

  void clearSearchResults() {
    _logger.d('Clearing search results');
    _searchResults = [];
    _lastSearchResponse = null;
    _lastSearchRequest = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _logger.d('Clearing error message');
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearSuccess() {
    if (_isSuccess || _successMessage != null) {
      _logger.d('Clearing success state');
      _isSuccess = false;
      _successMessage = null;
      notifyListeners();
    }
  }

  /// Resets all state to initial values (e.g., on logout).
  void reset() {
    _logger.d('Resetting LoanOfficerProvider');
    _pendingLoans = [];
    _searchResults = [];
    _lastSearchResponse = null;
    _selectedLoan = null;
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    _successMessage = null;
    _lastSearchRequest = null;
    _activeRequests.clear();
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Removes a loan from [_pendingLoans] after it has been approved/rejected.
  void _removeLoanFromPending(String loanId) {
    final before = _pendingLoans.length;
    _pendingLoans = _pendingLoans.where((l) => l.loanId != loanId).toList();
    final removed = before - _pendingLoans.length;
    if (removed > 0) {
      _logger.d('Removed $removed loan(s) from pending queue: $loanId');
    }
  }

  /// Updates a [LoanListItemModel] in [_searchResults] after a mutation.
  void _updateLoanInSearchResults(LoanResponseModel updatedLoan) {
    final index =
        _searchResults.indexWhere((l) => l.loanId == updatedLoan.loanId);
    if (index == -1) return;

    _searchResults[index] = LoanListItemModel(
      loanId: updatedLoan.loanId,
      loanType: updatedLoan.loanType,
      loanStatus: updatedLoan.loanStatus,
      approvalStatus: updatedLoan.approvalStatus,
      principal: updatedLoan.principal,
      outstandingBalance: updatedLoan.outstandingBalance,
      monthlyEMI: updatedLoan.monthlyEMI,
      applicationDate: updatedLoan.applicationDate,
      customerName: updatedLoan.customerName,
      customerId: updatedLoan.customerId,
    );
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _isSuccess = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setSuccess(String message) {
    _isSuccess = true;
    _successMessage = message;
    notifyListeners();
  }

  void _clearSuccess() {
    _isSuccess = false;
    _successMessage = null;
  }

  @override
  void dispose() {
    _logger.d('LoanOfficerProvider disposed');
    _activeRequests.clear();
    super.dispose();
  }
}
