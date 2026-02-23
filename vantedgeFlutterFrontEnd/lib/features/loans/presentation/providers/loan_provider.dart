import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';
import '../../data/models/loan_enums.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_application.dart';
import '../../data/models/loan_statement.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/loan_repository_impl.dart'; // LoanNotFoundException

/// Customer-facing provider for the Loan Management feature.
///
/// Manages the customer's own loan list, selected loan detail, loan statement,
/// and all mutating operations (apply, repay, foreclose).
///
/// Follows the exact pattern of [AccountProvider] / [TransactionProvider]:
///   - [ChangeNotifier] with guarded [_activeRequests] deduplication.
///   - Typed exception catch ladder (LoanNotFound → Forbidden → Unauthorized
///     → Network → Timeout → Api → catch-all).
///   - [_setLoading] / [_setError] / [_clearError] private helpers.
///   - [notifyListeners] called only after state mutation is complete.
class LoanProvider extends ChangeNotifier {
  final LoanRepository _repository;
  final Logger _logger = Logger();

  // ── State ────────────────────────────────────────────────────────────────

  List<LoanListItemModel> _myLoans = [];
  LoanResponseModel? _selectedLoan;
  LoanStatementModel? _loanStatement;
  TransactionHistoryModel? _lastRepaymentTransaction;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _successMessage;

  DateTime? _lastRefresh;

  final Set<String> _activeRequests = {};

  // ── Constructor ──────────────────────────────────────────────────────────

  LoanProvider({required LoanRepository repository})
      : _repository = repository {
    _logger.i('LoanProvider initialized');
  }

  // ── Read-only getters ────────────────────────────────────────────────────

  /// Unmodifiable list of the authenticated customer's loans.
  List<LoanListItemModel> get myLoans => List.unmodifiable(_myLoans);

  /// The currently selected/viewed loan detail.
  LoanResponseModel? get selectedLoan => _selectedLoan;

  /// The full statement (schedule + disbursements) for [selectedLoan].
  LoanStatementModel? get loanStatement => _loanStatement;

  /// The transaction record returned from the most recent [repayLoan] call.
  TransactionHistoryModel? get lastRepaymentTransaction =>
      _lastRepaymentTransaction;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  DateTime? get lastRefresh => _lastRefresh;

  // ── Computed getters ─────────────────────────────────────────────────────

  bool get hasLoans => _myLoans.isNotEmpty;

  /// Number of loans that are currently ACTIVE.
  int get activeLoanCount =>
      _myLoans.where((l) => l.loanStatus == LoanStatus.active).length;

  /// Number of loans with an APPROVED status (disbursement pending).
  int get approvedLoanCount =>
      _myLoans.where((l) => l.loanStatus == LoanStatus.approved).length;

  /// Number of loans still in APPLICATION or PROCESSING state.
  int get pendingLoanCount => _myLoans
      .where((l) => l.loanStatus.isPending)
      .length;

  /// Sum of [outstandingBalance] across all active loans.
  double get totalOutstanding => _myLoans.fold(
        0.0,
        (sum, l) =>
            l.loanStatus.isActive ? sum + (l.outstandingBalance ?? 0.0) : sum,
      );

  /// Sum of [monthlyEMI] across all active loans.
  double get totalMonthlyEMI => _myLoans.fold(
        0.0,
        (sum, l) =>
            l.loanStatus.isActive ? sum + (l.monthlyEMI ?? 0.0) : sum,
      );

  /// Whether there is a statement loaded for the current [selectedLoan].
  bool get hasStatement => _loanStatement != null;

  // ── Public actions ───────────────────────────────────────────────────────

  /// Loads the authenticated customer's loan list.
  ///
  /// Guarded: concurrent calls with the same requestId are silently dropped.
  Future<void> fetchMyLoans() async {
    const requestId = 'fetchMyLoans';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching my loans');

      final loans = await _repository.getMyLoans();

      _myLoans = loans;
      _lastRefresh = DateTime.now();
      _setLoading(false);

      _logger.i('Fetched ${loans.length} loans');
    } on NetworkException catch (e) {
      _logger.e('Network error fetching loans: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised fetching loans: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on TimeoutException catch (e) {
      _logger.e('Timeout fetching loans: ${e.message}');
      _setError('Request timed out. Please try again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching loans: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching loans: $e');
      _setError('Failed to load loans. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Loads full detail for a single loan and sets it as [selectedLoan].
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
      _setError('Loan not found. It may have been removed.');
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

  /// Loads the full statement (repayment schedule + disbursements) for [loanId]
  /// and stores it in [loanStatement].
  Future<void> fetchLoanStatement(String loanId) async {
    final requestId = 'fetchLoanStatement_$loanId';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching loan statement: $loanId');

      final statement = await _repository.getLoanStatement(loanId);

      _loanStatement = statement;
      _setLoading(false);

      _logger.i(
        'Statement fetched: $loanId '
        '(${statement.totalInstallments} installments, '
        '${statement.overdueInstallments.length} overdue)',
      );
    } on LoanNotFoundException catch (e) {
      _logger.e('Loan not found for statement: $loanId — ${e.message}');
      _setError('Loan not found.');
      _setLoading(false);
    } on ForbiddenException catch (e) {
      _logger.e('Access denied to statement for $loanId: ${e.message}');
      _setError('You do not have permission to view this statement.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error fetching statement $loanId: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised fetching statement $loanId: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching statement $loanId: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching statement $loanId: $e');
      _setError('Failed to load loan statement. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Submits a new loan application.
  ///
  /// Returns `true` on success. On success the new loan is prepended to
  /// [myLoans] so the UI updates without a full refresh.
  Future<bool> submitApplication(LoanApplicationModel request) async {
    const requestId = 'submitApplication';

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
        'Submitting loan application — '
        'customer: ${request.customerId}, '
        'type: ${request.loanType.displayName}, '
        'amount: ${request.loanAmount}',
      );

      final createdLoan = await _repository.applyForLoan(request);

      // Optimistically prepend to list so the UI shows it immediately.
      final listItem = LoanListItemModel(
        loanId: createdLoan.loanId,
        loanType: createdLoan.loanType,
        loanStatus: createdLoan.loanStatus,
        approvalStatus: createdLoan.approvalStatus,
        principal: createdLoan.principal,
        outstandingBalance: createdLoan.outstandingBalance,
        monthlyEMI: createdLoan.monthlyEMI,
        applicationDate: createdLoan.applicationDate,
        customerName: createdLoan.customerName,
        customerId: createdLoan.customerId,
      );
      _myLoans = [listItem, ..._myLoans];
      _selectedLoan = createdLoan;

      _setSuccess(
        'Loan application for ${request.loanType.displayName} submitted successfully.',
      );
      _setLoading(false);

      _logger.i('Loan application created: ${createdLoan.loanId}');
      return true;
    } on BadRequestException catch (e) {
      _logger.e('Validation error submitting application: ${e.message}');
      _setError(
        e.validationErrors != null && e.validationErrors!.isNotEmpty
            ? e.validationErrors!.values.first.toString()
            : e.message,
      );
      _setLoading(false);
      return false;
    } on ForbiddenException catch (e) {
      _logger.e('Forbidden submitting application: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error submitting application: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised submitting application: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error submitting application: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error submitting application: $e');
      _setError('Application submission failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Processes an EMI repayment for [loanId].
  ///
  /// [amount] must be ≥ 1.00.
  /// [paymentMode] one of [LoanPaymentMode] enum values.
  /// [date] the payment date (defaults to today if null).
  ///
  /// Returns `true` on success. On success [lastRepaymentTransaction] is
  /// updated and [selectedLoan] outstanding balance is cleared to trigger
  /// a UI refresh via [fetchLoanById].
  Future<bool> repayLoan({
    required String loanId,
    required double amount,
    required LoanPaymentMode paymentMode,
    required DateTime date,
    String? transactionReference,
  }) async {
    final requestId = 'repayLoan_$loanId';

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
        'Processing repayment — loan: $loanId, '
        'amount: $amount, mode: ${paymentMode.displayName}',
      );

      final request = LoanRepaymentRequestModel(
        loanId: loanId,
        paymentAmount: amount,
        paymentDate: date,
        paymentMode: paymentMode,
        transactionReference: transactionReference,
      );

      final transaction = await _repository.repayLoan(loanId, request);

      _lastRepaymentTransaction = transaction;

      // Invalidate the selected loan so the next detail view re-fetches fresh
      // data (outstanding balance will have changed server-side).
      if (_selectedLoan?.loanId == loanId) {
        _selectedLoan = null;
        _loanStatement = null;
      }

      _setSuccess(
        'Repayment of ৳${amount.toStringAsFixed(2)} processed successfully.',
      );
      _setLoading(false);

      _logger.i(
        'Repayment successful — txn: ${transaction.transactionId}',
      );
      return true;
    } on LoanNotFoundException catch (e) {
      _logger.e('Loan not found for repayment $loanId: ${e.message}');
      _setError('Loan not found.');
      _setLoading(false);
      return false;
    } on ForbiddenException catch (e) {
      _logger.e('Access denied for repayment $loanId: ${e.message}');
      _setError('You can only repay your own loans.');
      _setLoading(false);
      return false;
    } on BadRequestException catch (e) {
      _logger.e('Bad repayment request $loanId: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error during repayment $loanId: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised repayment $loanId: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error during repayment $loanId: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error during repayment $loanId: $e');
      _setError('Repayment failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Initiates early loan closure (foreclosure) for [loanId].
  ///
  /// [foreclosureDate] the date of closure.
  /// [settlementAccountNumber] the account from which the settlement is made.
  ///
  /// Returns `true` on success and removes the loan from [myLoans].
  Future<bool> forecloseLoan({
    required String loanId,
    required DateTime foreclosureDate,
    required String settlementAccountNumber,
  }) async {
    final requestId = 'forecloseLoan_$loanId';

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
        'Initiating foreclosure — loan: $loanId, '
        'date: ${foreclosureDate.toIso8601String().split("T").first}, '
        'settlement account: $settlementAccountNumber',
      );

      final request = LoanForeclosureRequestModel(
        loanId: loanId,
        foreclosureDate: foreclosureDate,
        settlementAccountNumber: settlementAccountNumber,
      );

      final updatedLoan = await _repository.forecloseLoan(loanId, request);

      // Update in-memory list with new status.
      _updateLoanInList(updatedLoan);

      // Clear selected if it was the foreclosed loan.
      if (_selectedLoan?.loanId == loanId) {
        _selectedLoan = updatedLoan;
        _loanStatement = null;
      }

      _setSuccess('Loan $loanId has been foreclosed successfully.');
      _setLoading(false);

      _logger.i('Loan foreclosed: $loanId');
      return true;
    } on LoanNotFoundException catch (e) {
      _logger.e('Loan not found for foreclosure $loanId: ${e.message}');
      _setError('Loan not found.');
      _setLoading(false);
      return false;
    } on ForbiddenException catch (e) {
      _logger.e('Access denied for foreclosure $loanId: ${e.message}');
      _setError('You can only foreclose your own loans.');
      _setLoading(false);
      return false;
    } on BadRequestException catch (e) {
      _logger.e('Bad foreclosure request $loanId: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error during foreclosure $loanId: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorised foreclosure $loanId: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error during foreclosure $loanId: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error during foreclosure $loanId: $e');
      _setError('Foreclosure failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  // ── Public UI helpers ─────────────────────────────────────────────────────

  /// Selects a loan for the detail view without triggering a network request.
  /// Pass [null] to deselect.
  void selectLoan(LoanResponseModel? loan) {
    _logger.d(loan != null
        ? 'Selecting loan: ${loan.loanId}'
        : 'Deselecting loan');
    _selectedLoan = loan;
    _loanStatement = null;
    notifyListeners();
  }

  void clearSelectedLoan() {
    _logger.d('Clearing selected loan');
    _selectedLoan = null;
    _loanStatement = null;
    notifyListeners();
  }

  void clearStatement() {
    _logger.d('Clearing loan statement');
    _loanStatement = null;
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
    _logger.d('Resetting LoanProvider');
    _myLoans = [];
    _selectedLoan = null;
    _loanStatement = null;
    _lastRepaymentTransaction = null;
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    _successMessage = null;
    _lastRefresh = null;
    _activeRequests.clear();
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Updates the [LoanListItemModel] in [_myLoans] whose loanId matches
  /// [updatedLoan]. A no-op if the loan is not in the list.
  void _updateLoanInList(LoanResponseModel updatedLoan) {
    final index = _myLoans.indexWhere((l) => l.loanId == updatedLoan.loanId);
    if (index == -1) return;

    _myLoans[index] = LoanListItemModel(
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
    _logger.d('LoanProvider disposed');
    _activeRequests.clear();
    super.dispose();
  }
}
