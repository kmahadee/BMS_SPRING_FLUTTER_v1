import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import '../../data/models/dps_model.dart';
import '../../data/models/dps_installment_model.dart';
import '../../data/models/dps_statement_model.dart';
import '../../data/models/maturity_calculation_model.dart';
import '../../data/models/dps_repository.dart';

class DpsProvider extends ChangeNotifier {
  final DpsRepository _repository;
  final Logger _logger = Logger();

  // ── State ──────────────────────────────────────────────────────────────────

  List<DpsModel> _dpsList = [];
  DpsModel? _selectedDps;
  List<DpsInstallmentModel> _installments = [];
  DpsStatementModel? _statement;
  MaturityCalculationModel? _maturityCalculation;

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _successMessage;

  final Set<String> _activeRequests = {};

  // ── Constructor ────────────────────────────────────────────────────────────

  DpsProvider({required DpsRepository repository})
      : _repository = repository {
    _logger.i('DpsProvider initialized');
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  List<DpsModel> get dpsList => List.unmodifiable(_dpsList);
  DpsModel? get selectedDps => _selectedDps;
  List<DpsInstallmentModel> get installments => List.unmodifiable(_installments);
  DpsStatementModel? get statement => _statement;
  MaturityCalculationModel? get maturityCalculation => _maturityCalculation;

  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get hasError => _errorMessage != null;
  bool get hasDps => _dpsList.isNotEmpty;

  // ── Public async methods ───────────────────────────────────────────────────

  /// GET /api/dps/customer/{customerId}
  Future<void> fetchMyDps(String customerId) async {
    const requestId = 'fetchMyDps';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching DPS accounts for customer: $customerId');

      final accounts = await _repository.getMyDps(customerId);

      _dpsList = accounts;
      _setLoading(false);

      _logger.i('Fetched ${accounts.length} DPS accounts');
    } on NetworkException catch (e) {
      _logger.e('Network error fetching DPS list: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized fetching DPS list: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on TimeoutException catch (e) {
      _logger.e('Timeout fetching DPS list: ${e.message}');
      _setError('Request timed out. Please try again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching DPS list: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching DPS list: $e');
      _setError('Failed to load DPS accounts. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// GET /api/dps/number/{dpsNumber}
  Future<void> fetchDpsByNumber(String dpsNumber) async {
    final requestId = 'fetchDpsByNumber_$dpsNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching DPS by number: $dpsNumber');

      final dps = await _repository.getDpsByNumber(dpsNumber);

      _selectedDps = dps;
      _setLoading(false);

      _logger.i('Fetched DPS: $dpsNumber');
    } on DpsNotFoundException catch (e) {
      _logger.e('DPS not found: ${e.dpsNumber}');
      _setError('DPS account not found.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error fetching DPS: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized access to DPS: ${e.message}');
      _setError('You are not authorized to view this DPS account.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching DPS: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching DPS: $e');
      _setError('Failed to load DPS details. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// GET /api/dps/statement/{dpsNumber} — parses installments[] only
  Future<void> fetchInstallments(String dpsNumber) async {
    final requestId = 'fetchInstallments_$dpsNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching installments for DPS: $dpsNumber');

      final result = await _repository.getInstallments(dpsNumber);

      _installments = result;
      _setLoading(false);

      _logger.i('Fetched ${result.length} installments for DPS: $dpsNumber');
    } on DpsNotFoundException catch (e) {
      _logger.e('DPS not found when fetching installments: ${e.dpsNumber}');
      _setError('DPS account not found.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error fetching installments: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized fetching installments: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching installments: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching installments: $e');
      _setError('Failed to load installments. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// GET /api/dps/statement/{dpsNumber}
  Future<void> fetchStatement(String dpsNumber) async {
    final requestId = 'fetchStatement_$dpsNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching statement for DPS: $dpsNumber');

      final result = await _repository.getDpsStatement(dpsNumber);

      _statement = result;
      _setLoading(false);

      _logger.i(
        'Statement fetched for DPS: $dpsNumber '
        '(${result.totalInstallments} installments)',
      );
    } on DpsNotFoundException catch (e) {
      _logger.e('DPS not found when fetching statement: ${e.dpsNumber}');
      _setError('DPS account not found.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error fetching statement: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized fetching statement: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching statement: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching statement: $e');
      _setError('Failed to load statement. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// GET /api/dps/calculate-maturity
  Future<void> calculateMaturity({
    required double monthly,
    required int tenure,
    required double rate,
  }) async {
    const requestId = 'calculateMaturity';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i(
        'Calculating maturity — installment: $monthly, '
        'tenure: $tenure months, rate: $rate%',
      );

      final result = await _repository.calculateMaturity(
        monthlyInstallment: monthly,
        tenureMonths: tenure,
        interestRate: rate,
      );

      _maturityCalculation = result;
      _setLoading(false);

      _logger.i('Maturity calculated: ${result.maturityAmount}');
    } on NetworkException catch (e) {
      _logger.e('Network error calculating maturity: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on BadRequestException catch (e) {
      _logger.e('Invalid parameters for maturity calculation: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error calculating maturity: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error calculating maturity: $e');
      _setError('Failed to calculate maturity. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// POST /api/dps
  Future<bool> createDps(Map<String, dynamic> body) async {
    const requestId = 'createDps';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i('Creating DPS for customer: ${body['customerId']}');

      final dps = await _repository.createDps(body);

      _dpsList = [..._dpsList, dps];
      _setSuccess('DPS account ${dps.dpsNumber} created successfully.');
      _setLoading(false);

      _logger.i('DPS created: ${dps.dpsNumber}');
      return true;
    } on BadRequestException catch (e) {
      _logger.e('Validation error creating DPS: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error creating DPS: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized creating DPS: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error creating DPS: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error creating DPS: $e');
      _setError('Failed to create DPS account. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// POST /api/dps/pay-installment
  Future<bool> payInstallment(Map<String, dynamic> body) async {
    const requestId = 'payInstallment';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i('Paying installment for DPS: ${body['dpsNumber']}');

      await _repository.payInstallment(body);

      // Refresh installments list after successful payment
      final dpsNumber = body['dpsNumber'] as String?;
      if (dpsNumber != null) {
        final updated = await _repository.getInstallments(dpsNumber);
        _installments = updated;
      }

      _setSuccess('Installment payment completed successfully.');
      _setLoading(false);

      _logger.i('Installment paid for DPS: ${body['dpsNumber']}');
      return true;
    } on BadRequestException catch (e) {
      _logger.e('Validation error paying installment: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on DpsNotFoundException catch (e) {
      _logger.e('DPS not found for payment: ${e.dpsNumber}');
      _setError('DPS account not found.');
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error paying installment: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized installment payment: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error paying installment: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error paying installment: $e');
      _setError('Payment failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// PATCH /api/dps/{dpsNumber}/close
  Future<bool> closeDps(String dpsNumber, {String? reason}) async {
    final requestId = 'closeDps_$dpsNumber';

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
        'Closing DPS: $dpsNumber'
        '${reason != null ? ' — reason: $reason' : ''}',
      );

      final updated = await _repository.closeDps(dpsNumber, reason: reason);

      // Update the entry in dpsList
      _dpsList = _dpsList.map((d) {
        return d.dpsNumber == dpsNumber ? updated : d;
      }).toList();

      // Reflect on selectedDps if it's the same account
      if (_selectedDps?.dpsNumber == dpsNumber) {
        _selectedDps = updated;
      }

      _setSuccess('DPS account $dpsNumber has been closed.');
      _setLoading(false);

      _logger.i('DPS closed: $dpsNumber');
      return true;
    } on DpsNotFoundException catch (e) {
      _logger.e('DPS not found for closure: ${e.dpsNumber}');
      _setError('DPS account not found.');
      _setLoading(false);
      return false;
    } on ForbiddenException catch (e) {
      _logger.e('Access denied closing DPS: ${e.message}');
      _setError(e.message.isNotEmpty
          ? e.message
          : 'You do not have permission to close this DPS account.');
      _setLoading(false);
      return false;
    } on BadRequestException catch (e) {
      _logger.e('Invalid request closing DPS: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error closing DPS: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized closing DPS: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error closing DPS: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error closing DPS: $e');
      _setError('Failed to close DPS account. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  // ── Public utility methods ─────────────────────────────────────────────────

  /// Call after showing a SnackBar so messages don't persist across screens.
  void clearMessages() {
    if (_errorMessage != null || _successMessage != null || _isSuccess) {
      _logger.d('Clearing DPS messages');
      _errorMessage = null;
      _successMessage = null;
      _isSuccess = false;
      notifyListeners();
    }
  }

  /// Reset the maturity calculator panel without touching other state.
  void clearMaturityCalculation() {
    _logger.d('Clearing maturity calculation');
    _maturityCalculation = null;
    notifyListeners();
  }

  void clearSelectedDps() {
    _logger.d('Clearing selected DPS');
    _selectedDps = null;
    _statement = null;
    _installments = [];
    notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

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
    _logger.d('DpsProvider disposed');
    _activeRequests.clear();
    super.dispose();
  }
}
