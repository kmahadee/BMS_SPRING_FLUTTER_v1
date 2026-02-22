import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/constants/api_constants.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';

/// Provides live badge counts for pending items used in the
/// [AppDrawer] and [BottomNavBar].
///
/// Usage — register in main.dart alongside other providers:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => BadgeCountProvider(dioClient: dioClient),
/// ),
/// ```
///
/// Then consume in AppDrawer / BottomNavBar:
/// ```dart
/// final counts = context.watch<BadgeCountProvider>();
/// badgeCount: counts.pendingLoanApprovals,
/// ```
class BadgeCountProvider extends ChangeNotifier {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  // ── Counts ────────────────────────────────────────────────────────────────

  /// Loans with status PENDING — shown on Branch Manager "Approvals" badge.
  int _pendingLoanApprovals = 0;

  /// Loans with status PENDING — shown on Loan Officer "Applications" badge.
  int _pendingLoanApplications = 0;

  /// Loans with status APPROVED — shown on Loan Officer "Approvals" badge
  /// (ready to disburse).
  int _approvedLoans = 0;

  /// Cards with status PENDING — shown on Card Officer "Applications" badge.
  int _pendingCardApplications = 0;

  bool _isLoading = false;
  String? _errorMessage;

  BadgeCountProvider({required DioClient dioClient}) : _dioClient = dioClient;

  // ── Getters ───────────────────────────────────────────────────────────────

  int get pendingLoanApprovals => _pendingLoanApprovals;
  int get pendingLoanApplications => _pendingLoanApplications;
  int get approvedLoans => _approvedLoans;
  int get pendingCardApplications => _pendingCardApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call once after login, and optionally on a periodic timer.
  Future<void> refresh() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await Future.wait([
        _fetchLoanCounts(),
        _fetchCardCounts(),
      ]);
    } on UnauthorizedException {
      _errorMessage = 'Session expired.';
    } on NetworkException {
      _errorMessage = 'Network error fetching badge counts.';
    } catch (e) {
      _logger.w('BadgeCountProvider.refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset all counts to zero (call on logout).
  void clear() {
    _pendingLoanApprovals = 0;
    _pendingLoanApplications = 0;
    _approvedLoans = 0;
    _pendingCardApplications = 0;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _fetchLoanCounts() async {
    try {
      final response =
          await _dioClient.get<Map<String, dynamic>>(ApiConstants.getAllLoans);

      final data = response['data'];
      if (data == null) return;

      final loans = List<Map<String, dynamic>>.from(data as List);

      _pendingLoanApprovals = loans
          .where((l) => _statusEquals(l['status'], 'PENDING'))
          .length;

      // Loan officer sees same PENDING list as applications to review
      _pendingLoanApplications = _pendingLoanApprovals;

      _approvedLoans = loans
          .where((l) => _statusEquals(l['status'], 'APPROVED'))
          .length;

      _logger.d(
        'Loan counts — pending: $_pendingLoanApprovals, approved: $_approvedLoans',
      );
    } catch (e) {
      _logger.w('_fetchLoanCounts error: $e');
    }
  }

  Future<void> _fetchCardCounts() async {
    try {
      final response =
          await _dioClient.get<Map<String, dynamic>>(ApiConstants.getAllCards);

      final data = response['data'];
      if (data == null) return;

      final cards = List<Map<String, dynamic>>.from(data as List);

      _pendingCardApplications = cards
          .where((c) => _statusEquals(c['status'], 'PENDING'))
          .length;

      _logger.d('Card counts — pending: $_pendingCardApplications');
    } catch (e) {
      _logger.w('_fetchCardCounts error: $e');
    }
  }

  bool _statusEquals(dynamic value, String expected) {
    if (value == null) return false;
    return value.toString().toUpperCase() == expected;
  }
}