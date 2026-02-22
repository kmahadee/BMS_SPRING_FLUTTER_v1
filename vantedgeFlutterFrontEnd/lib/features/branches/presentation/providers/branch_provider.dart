import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import '../../data/models/branch_response_dto.dart';
import '../../data/models/branch_statistics_dto.dart';
import '../../data/repositories/branch_repository.dart';
import '../../domain/exceptions/branch_not_found_exception.dart';

/// Provider for managing branch-related state and operations
/// 
/// This provider follows the ChangeNotifier pattern and coordinates with
/// [BranchRepository] to fetch and manage branch data. It handles loading
/// states, errors, and leverages the repository's caching mechanism.
class BranchProvider extends ChangeNotifier {
  final BranchRepository _repository;
  final Logger _logger = Logger();

  // State properties
  List<BranchResponseDTO> _branches = [];
  BranchResponseDTO? _selectedBranch;
  BranchStatisticsDTO? _branchStats;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastRefresh;

  // Search results (separate from main list)
  List<BranchResponseDTO> _searchResults = [];
  bool _isSearchMode = false;

  // Concurrent request management
  final Set<String> _activeRequests = {};

  BranchProvider({
    required BranchRepository repository,
  }) : _repository = repository {
    _logger.i('BranchProvider initialized');
  }

  // Getters
  List<BranchResponseDTO> get branches => List.unmodifiable(_branches);
  BranchResponseDTO? get selectedBranch => _selectedBranch;
  BranchStatisticsDTO? get branchStats => _branchStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefresh => _lastRefresh;
  bool get hasBranches => _branches.isNotEmpty;
  bool get hasError => _errorMessage != null;
  bool get isSearchMode => _isSearchMode;
  List<BranchResponseDTO> get searchResults => List.unmodifiable(_searchResults);

  /// Get count of active branches
  int get activeBranchesCount {
    return _branches.where((branch) => branch.isActive).length;
  }

  /// Get branches grouped by city
  Map<String, List<BranchResponseDTO>> get branchesByCity {
    final Map<String, List<BranchResponseDTO>> grouped = {};
    for (final branch in _branches) {
      grouped.putIfAbsent(branch.city, () => []).add(branch);
    }
    return grouped;
  }

  /// Get list of unique cities
  List<String> get cities {
    return _branches.map((b) => b.city).toSet().toList()..sort();
  }

  /// Fetches all branches from the repository
  /// 
  /// Uses the repository's caching mechanism for better performance.
  /// Supports pull-to-refresh pattern.
  Future<void> fetchAllBranches({bool forceRefresh = false}) async {
    final requestId = 'fetchAllBranches';
    
    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _isSearchMode = false;

      _logger.i('Fetching all branches (forceRefresh: $forceRefresh)');

      // Clear cache if force refresh
      if (forceRefresh) {
        _repository.clearCache();
      }

      final branches = await _repository.getAllBranches();

      _branches = branches;
      _lastRefresh = DateTime.now();
      _setLoading(false);

      _logger.i('Fetched ${branches.length} branches successfully');
    } on NetworkException catch (e) {
      _logger.e('Network error fetching branches: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized error: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on TimeoutException catch (e) {
      _logger.e('Timeout error: ${e.message}');
      _setError('Request timed out. Please try again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching branches: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching branches: $e');
      _setError('Failed to load branches. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Fetches detailed information for a specific branch
  /// 
  /// [branchId] The branch ID to fetch details for
  Future<void> fetchBranchDetails(int branchId) async {
    final requestId = 'fetchBranchDetails_$branchId';
    
    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching branch details for ID: $branchId');

      final branch = await _repository.getBranchById(branchId);

      _selectedBranch = branch;
      _setLoading(false);

      _logger.i('Branch details fetched successfully: ${branch.branchName}');

      // Also fetch statistics if user has permission
      await fetchBranchStatistics(branchId);
    } on BranchNotFoundException catch (e) {
      _logger.e('Branch not found: ${e.branchId}');
      _setError('Branch not found. Please check the branch ID.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized: ${e.message}');
      _setError('You are not authorized to view this branch.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error: $e');
      _setError('Failed to load branch details.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Fetches statistics for a specific branch
  /// 
  /// [branchId] The branch ID to fetch statistics for
  /// 
  /// This method fails silently if user doesn't have permission.
  Future<void> fetchBranchStatistics(int branchId) async {
    final requestId = 'fetchBranchStatistics_$branchId';
    
    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _clearError();

      _logger.i('Fetching statistics for branch ID: $branchId');

      final stats = await _repository.getBranchStatistics(branchId);

      _branchStats = stats;
      notifyListeners();

      _logger.i(
        'Statistics fetched for branch $branchId: '
        '${stats.totalAccounts} accounts, ${stats.totalCustomers} customers',
      );
    } on BranchNotFoundException catch (e) {
      _logger.e('Branch not found: ${e.branchId}');
      _branchStats = null;
      notifyListeners();
    } on ForbiddenException catch (e) {
      _logger.w('No permission to view statistics: ${e.message}');
      // Don't show error - user just doesn't have permission
      _branchStats = null;
      notifyListeners();
    } on NetworkException catch (e) {
      _logger.w('Network error fetching statistics: ${e.message}');
      // Silent failure for statistics
    } on ApiException catch (e) {
      _logger.w('Error fetching statistics: ${e.message}');
      // Silent failure for statistics
    } catch (e) {
      _logger.e('Unexpected error fetching statistics: $e');
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Searches for branches in a specific city
  /// 
  /// [city] The city name to search for
  Future<void> searchBranchesByCity(String city) async {
    final requestId = 'searchBranchesByCity_$city';
    
    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _isSearchMode = true;

      _logger.i('Searching branches in city: $city');

      final results = await _repository.getBranchesByCity(city);

      _searchResults = results;
      _setLoading(false);

      _logger.i('Found ${results.length} branches in $city');
    } on BadRequestException catch (e) {
      _logger.e('Invalid city name: ${e.message}');
      _setError('Invalid city name. Please try again.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _setError('No internet connection.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error searching branches: $e');
      _setError('Search failed. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Finds a branch by IFSC code
  /// 
  /// [ifscCode] The IFSC code to search for
  Future<void> findBranchByIfsc(String ifscCode) async {
    final requestId = 'findBranchByIfsc_$ifscCode';
    
    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Finding branch by IFSC: $ifscCode');

      final branch = await _repository.getBranchByIfscCode(ifscCode);

      _selectedBranch = branch;
      _setLoading(false);

      _logger.i('Branch found: ${branch.branchName}');
    } on BranchNotFoundException catch (e) {
      _logger.e('Branch not found for IFSC: ${e.ifscCode}');
      _setError('No branch found with IFSC code: $ifscCode');
      _setLoading(false);
    } on BadRequestException catch (e) {
      _logger.e('Invalid IFSC code: ${e.message}');
      _setError('Invalid IFSC code format.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _setError('No internet connection.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error: $e');
      _setError('Search failed. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Filters branches by status
  /// 
  /// [status] The status to filter by (ACTIVE, INACTIVE, CLOSED)
  Future<void> filterByStatus(String status) async {
    final requestId = 'filterByStatus_$status';
    
    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _isSearchMode = true;

      _logger.i('Filtering branches by status: $status');

      final results = await _repository.getBranchesByStatus(status);

      _searchResults = results;
      _setLoading(false);

      _logger.i('Found ${results.length} branches with status: $status');
    } on BadRequestException catch (e) {
      _logger.e('Invalid status: ${e.message}');
      _setError('Invalid status. Please try again.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _setError('No internet connection.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error filtering branches: $e');
      _setError('Filter failed. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Selects a branch from the list to view details
  /// 
  /// [branch] The branch to select
  void selectBranch(BranchResponseDTO branch) {
    _logger.d('Selecting branch: ${branch.branchName}');
    
    // Clear current selection first
    _selectedBranch = null;
    _branchStats = null;
    
    notifyListeners();
    
    // Fetch full details asynchronously
    fetchBranchDetails(branch.id);
  }

  /// Clears the currently selected branch and statistics
  void clearSelectedBranch() {
    _logger.d('Clearing selected branch');
    _selectedBranch = null;
    _branchStats = null;
    notifyListeners();
  }

  /// Exits search mode and returns to full branch list
  void exitSearchMode() {
    _logger.d('Exiting search mode');
    _isSearchMode = false;
    _searchResults = [];
    notifyListeners();
  }

  /// Clears any error message
  void clearError() {
    if (_errorMessage != null) {
      _logger.d('Clearing error message');
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Forces a cache refresh on next fetch
  void clearCache() {
    _logger.i('Clearing branch cache');
    _repository.clearCache();
  }

  /// Sets loading state and notifies listeners
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Sets error message and notifies listeners
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears error without notifying (used internally)
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _logger.d('BranchProvider disposed');
    _activeRequests.clear();
    super.dispose();
  }
}