import '../models/branch_response_dto.dart';
import '../models/branch_statistics_dto.dart';

/// Abstract repository interface for branch-related operations
/// 
/// This interface defines the contract for all branch data operations.
/// Implementations should handle API calls, error handling, and data transformation.
abstract class BranchRepository {
  /// Retrieves all branches in the banking system
  /// 
  /// Returns a list of [BranchResponseDTO] containing complete branch information.
  /// This list may be cached for performance optimization.
  /// 
  /// Throws:
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<List<BranchResponseDTO>> getAllBranches();

  /// Retrieves detailed information for a specific branch by ID
  /// 
  /// [branchId] The unique branch ID to fetch
  /// 
  /// Returns [BranchResponseDTO] with complete branch details
  /// 
  /// Throws:
  /// - [BranchNotFoundException] if the branch doesn't exist
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<BranchResponseDTO> getBranchById(int branchId);

  /// Retrieves statistics for a specific branch
  /// 
  /// [branchId] The branch ID to get statistics for
  /// 
  /// Returns [BranchStatisticsDTO] with aggregated metrics and performance data
  /// 
  /// Throws:
  /// - [BranchNotFoundException] if the branch doesn't exist
  /// - [ForbiddenException] if user doesn't have permission to view statistics
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<BranchStatisticsDTO> getBranchStatistics(int branchId);

  /// Retrieves all branches in a specific city
  /// 
  /// [city] The city name to filter branches by
  /// 
  /// Returns a list of [BranchResponseDTO] for branches in the specified city
  /// 
  /// Throws:
  /// - [BadRequestException] if city name is invalid
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<List<BranchResponseDTO>> getBranchesByCity(String city);

  /// Retrieves a branch by its IFSC code
  /// 
  /// [ifscCode] The IFSC (Indian Financial System Code) to search for
  /// 
  /// Returns [BranchResponseDTO] for the matching branch
  /// 
  /// Throws:
  /// - [BranchNotFoundException] if no branch with the IFSC code exists
  /// - [BadRequestException] if IFSC code format is invalid
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<BranchResponseDTO> getBranchByIfscCode(String ifscCode);

  /// Retrieves a branch by its branch code
  /// 
  /// [branchCode] The unique branch code to search for
  /// 
  /// Returns [BranchResponseDTO] for the matching branch
  /// 
  /// Throws:
  /// - [BranchNotFoundException] if no branch with the code exists
  /// - [BadRequestException] if branch code format is invalid
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<BranchResponseDTO> getBranchByCode(String branchCode);

  /// Retrieves branches filtered by status
  /// 
  /// [status] The branch status to filter by (ACTIVE, INACTIVE, CLOSED)
  /// 
  /// Returns a list of [BranchResponseDTO] matching the status
  /// 
  /// Throws:
  /// - [BadRequestException] if status is invalid
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [ApiException] for other API errors
  Future<List<BranchResponseDTO>> getBranchesByStatus(String status);

  /// Retrieves bank-wide statistics across all branches
  /// 
  /// Returns aggregated statistics for the entire banking system.
  /// Requires administrative privileges.
  /// 
  /// Throws:
  /// - [ForbiddenException] if user doesn't have admin permissions
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<Map<String, dynamic>> getBankStatistics();

  /// Clears the cached branch list
  /// 
  /// Forces the next call to [getAllBranches] to fetch fresh data from the API.
  /// Useful when branch data has been updated and cache needs to be invalidated.
  void clearCache();
}