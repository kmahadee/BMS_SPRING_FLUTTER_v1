import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/constants/api_constants_extension.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import '../models/branch_response_dto.dart';
import '../models/branch_statistics_dto.dart';
import '../../domain/exceptions/branch_not_found_exception.dart';
import 'branch_repository.dart';

/// Implementation of [BranchRepository] for branch-related operations
/// 
/// This implementation uses [DioClient] to make HTTP requests to the backend API.
/// It includes comprehensive error handling, logging, retry logic, and an optional
/// caching mechanism for branch list to improve performance.
class BranchRepositoryImpl implements BranchRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  /// Maximum number of retry attempts for failed requests
  static const int _maxRetries = 2;

  /// Delay between retry attempts
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// Cache duration for branch list (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Cached branch list
  List<BranchResponseDTO>? _cachedBranches;

  /// Timestamp of when branches were cached
  DateTime? _cacheTimestamp;

  /// Ongoing cache fetch operation to prevent duplicate requests
  Future<List<BranchResponseDTO>>? _ongoingCacheFetch;

  BranchRepositoryImpl({
    required DioClient dioClient,
  }) : _dioClient = dioClient;

  @override
  Future<List<BranchResponseDTO>> getAllBranches() async {
    // Check if cache is valid
    if (_isCacheValid()) {
      _logger.d('Returning cached branches (${_cachedBranches!.length} branches)');
      return _cachedBranches!;
    }

    // Prevent duplicate simultaneous requests
    if (_ongoingCacheFetch != null) {
      _logger.d('Cache fetch already in progress, waiting for result');
      return _ongoingCacheFetch!;
    }

    _ongoingCacheFetch = _executeWithRetry(
      operation: () async {
        _logger.i('Fetching all branches');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.allBranches,
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final List<dynamic> branchesList = data as List<dynamic>;
        final branches = branchesList
            .map((json) => BranchResponseDTO.fromJson(json as Map<String, dynamic>))
            .toList();

        // Update cache
        _cachedBranches = branches;
        _cacheTimestamp = DateTime.now();

        _logger.i('Fetched ${branches.length} branches (cached for ${_cacheDuration.inMinutes} minutes)');
        return branches;
      },
      operationName: 'getAllBranches',
    );

    try {
      final result = await _ongoingCacheFetch!;
      return result;
    } finally {
      _ongoingCacheFetch = null;
    }
  }

  @override
  Future<BranchResponseDTO> getBranchById(int branchId) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching branch details for ID: $branchId');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getBranchById(branchId),
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final branch = BranchResponseDTO.fromJson(data as Map<String, dynamic>);

        _logger.i('Branch details fetched successfully: ${branch.branchName}');
        return branch;
      },
      operationName: 'getBranchById',
      onError: (error) => _handleBranchError(error, branchId: branchId),
    );
  }

  @override
  Future<BranchStatisticsDTO> getBranchStatistics(int branchId) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching statistics for branch ID: $branchId');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getBranchStatistics(branchId),
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final statistics = BranchStatisticsDTO.fromJson(data as Map<String, dynamic>);

        _logger.i(
          'Statistics fetched for branch $branchId: '
          '${statistics.totalAccounts} accounts, ${statistics.totalCustomers} customers',
        );
        return statistics;
      },
      operationName: 'getBranchStatistics',
      onError: (error) => _handleBranchError(error, branchId: branchId),
    );
  }

  @override
  Future<List<BranchResponseDTO>> getBranchesByCity(String city) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching branches in city: $city');

        // Validate city name
        if (city.trim().isEmpty) {
          throw const BadRequestException(
            message: 'City name cannot be empty',
          );
        }

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getBranchesByCity(city),
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final List<dynamic> branchesList = data as List<dynamic>;
        final branches = branchesList
            .map((json) => BranchResponseDTO.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${branches.length} branches in $city');
        return branches;
      },
      operationName: 'getBranchesByCity',
    );
  }

  @override
  Future<BranchResponseDTO> getBranchByIfscCode(String ifscCode) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching branch by IFSC code: $ifscCode');

        // Validate IFSC code format (basic validation)
        if (ifscCode.trim().isEmpty) {
          throw const BadRequestException(
            message: 'IFSC code cannot be empty',
          );
        }

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getBranchByIfsc(ifscCode),
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final branch = BranchResponseDTO.fromJson(data as Map<String, dynamic>);

        _logger.i('Branch found for IFSC $ifscCode: ${branch.branchName}');
        return branch;
      },
      operationName: 'getBranchByIfscCode',
      onError: (error) => _handleBranchError(error, ifscCode: ifscCode),
    );
  }

  @override
  Future<BranchResponseDTO> getBranchByCode(String branchCode) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching branch by code: $branchCode');

        // Validate branch code
        if (branchCode.trim().isEmpty) {
          throw const BadRequestException(
            message: 'Branch code cannot be empty',
          );
        }

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getBranchByCode(branchCode),
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final branch = BranchResponseDTO.fromJson(data as Map<String, dynamic>);

        _logger.i('Branch found for code $branchCode: ${branch.branchName}');
        return branch;
      },
      operationName: 'getBranchByCode',
      onError: (error) => _handleBranchError(error, branchCode: branchCode),
    );
  }

  @override
  Future<List<BranchResponseDTO>> getBranchesByStatus(String status) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching branches with status: $status');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getBranchesByStatus(status),
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final List<dynamic> branchesList = data as List<dynamic>;
        final branches = branchesList
            .map((json) => BranchResponseDTO.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${branches.length} branches with status: $status');
        return branches;
      },
      operationName: 'getBranchesByStatus',
    );
  }

  @override
  Future<Map<String, dynamic>> getBankStatistics() async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching bank-wide statistics');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.bankStatistics,
        );

        final data = response['data'];
        if (data == null) {
          throw const ApiException(
            message: 'Response data is null',
            statusCode: 500,
          );
        }

        final statistics = data as Map<String, dynamic>;

        _logger.i('Bank statistics fetched successfully');
        return statistics;
      },
      operationName: 'getBankStatistics',
    );
  }

  @override
  void clearCache() {
    _cachedBranches = null;
    _cacheTimestamp = null;
    _logger.d('Branch cache cleared');
  }

  /// Checks if the cached branch list is still valid
  /// 
  /// Returns true if cache exists and is within the cache duration
  bool _isCacheValid() {
    if (_cachedBranches == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);

    return cacheAge < _cacheDuration;
  }

  /// Executes an operation with retry logic for transient failures
  /// 
  /// [operation] The async operation to execute
  /// [operationName] Name of the operation for logging
  /// [onError] Optional error handler for custom error transformation
  /// 
  /// Retries the operation up to [_maxRetries] times for network and timeout errors.
  /// Non-retryable errors are thrown immediately.
  Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    void Function(dynamic error)? onError,
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        // Determine if error is retryable
        final isRetryable = _isRetryableError(e);
        final shouldRetry = isRetryable && retryCount < _maxRetries;

        if (shouldRetry) {
          retryCount++;
          _logger.w(
            '$operationName failed (attempt $retryCount/$_maxRetries), retrying after ${_retryDelay.inMilliseconds * retryCount}ms: $e',
          );
          // Exponential backoff: 500ms, 1000ms, 2000ms
          await Future.delayed(_retryDelay * (1 << (retryCount - 1)));
          continue;
        }

        // Not retryable or max retries reached - handle custom error transformation
        _logger.e('$operationName failed after $retryCount retries: $e');
        
        if (onError != null) {
          onError(e);
        }
        
        rethrow;
      }
    }
  }

  /// Determines if an error is retryable
  /// 
  /// Returns true for network errors and timeouts, false for other errors.
  bool _isRetryableError(dynamic error) {
    return error is NetworkException || 
           error is TimeoutException ||
           (error is ApiException && error.statusCode == 503); // Service Unavailable
  }

  /// Handles branch-specific errors and transforms them into appropriate exceptions
  /// 
  /// [error] The error to handle
  /// [branchId] Optional branch ID associated with the error
  /// [branchCode] Optional branch code associated with the error
  /// [ifscCode] Optional IFSC code associated with the error
  void _handleBranchError(
    dynamic error, {
    int? branchId,
    String? branchCode,
    String? ifscCode,
  }) {
    if (error is NotFoundException) {
      // Transform to BranchNotFoundException with appropriate context
      if (branchId != null) {
        throw BranchNotFoundException.forBranchId(
          branchId,
          data: error.data,
          stackTrace: error.stackTrace,
        );
      } else if (branchCode != null) {
        throw BranchNotFoundException.forBranchCode(
          branchCode,
          data: error.data,
          stackTrace: error.stackTrace,
        );
      } else if (ifscCode != null) {
        throw BranchNotFoundException.forIfscCode(
          ifscCode,
          data: error.data,
          stackTrace: error.stackTrace,
        );
      } else {
        throw BranchNotFoundException(
          message: error.message,
          data: error.data,
          stackTrace: error.stackTrace,
        );
      }
    }

    // Handle ForbiddenException for statistics access
    if (error is ForbiddenException) {
      _logger.w('Access denied to branch statistics or details');
      throw error;
    }

    // Handle BadRequestException for validation errors
    if (error is BadRequestException) {
      _logger.w('Validation error: ${error.message}');
      throw error;
    }

    // Handle UnauthorizedException
    if (error is UnauthorizedException) {
      _logger.w('Unauthorized access to branch data');
      throw error;
    }

    // For other errors, just rethrow
    if (error is ApiException) {
      _logger.e('API error: ${error.message}');
      throw error;
    }
  }
}