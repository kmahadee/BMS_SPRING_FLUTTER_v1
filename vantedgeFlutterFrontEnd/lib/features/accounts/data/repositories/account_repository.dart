import '../models/account_list_item_dto.dart';
import '../models/account_response_dto.dart';
import '../models/account_balance_dto.dart';
import '../models/account_statement_dto.dart';

/// Abstract repository interface for account-related operations
/// 
/// This interface defines the contract for all account data operations.
/// Implementations should handle API calls, error handling, and data transformation.
abstract class AccountRepository {
  /// Retrieves all accounts belonging to the authenticated user
  /// 
  /// Returns a list of [AccountListItemDTO] containing lightweight account information
  /// suitable for list views.
  /// 
  /// Throws:
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  // Future<List<AccountListItemDTO>> getMyAccounts();
  Future<List<AccountListItemDTO>> getMyAccounts(String customerId);

  /// Retrieves detailed information for a specific account by account number
  /// 
  /// [accountNumber] The unique account number to fetch
  /// 
  /// Returns [AccountResponseDTO] with complete account details
  /// 
  /// Throws:
  /// - [AccountNotFoundException] if the account doesn't exist or user has no access
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<AccountResponseDTO> getAccountByNumber(String accountNumber);

  /// Retrieves the current balance for a specific account
  /// 
  /// [accountNumber] The account number to get balance for
  /// 
  /// Returns [AccountBalanceDTO] with current and available balance information
  /// 
  /// Throws:
  /// - [AccountNotFoundException] if the account doesn't exist
  /// - [AccountInactiveException] if the account is not active
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<AccountBalanceDTO> getAccountBalance(String accountNumber);

  /// Generates an account statement for a specified date range
  /// 
  /// [accountNumber] The account number to generate statement for
  /// [fromDate] Start date of the statement period
  /// [toDate] End date of the statement period
  /// 
  /// Returns [AccountStatementDTO] with transactions and balance information
  /// 
  /// Throws:
  /// - [AccountNotFoundException] if the account doesn't exist
  /// - [BadRequestException] if date range is invalid
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<AccountStatementDTO> generateStatement(
    String accountNumber,
    DateTime fromDate,
    DateTime toDate,
  );

  /// Retrieves all accounts associated with a specific customer ID
  /// 
  /// [customerId] The customer ID to fetch accounts for
  /// 
  /// Returns a list of [AccountListItemDTO] for the specified customer
  /// 
  /// Throws:
  /// - [NotFoundException] if the customer doesn't exist
  /// - [UnauthorizedException] if the user doesn't have permission
  /// - [NetworkException] if there's a network connectivity issue
  /// - [TimeoutException] if the request times out
  /// - [ApiException] for other API errors
  Future<List<AccountListItemDTO>> getAccountsByCustomerId(String customerId);

  /// Freezes an account to prevent transactions
  /// 
  /// [accountNumber] The account number to freeze
  /// 
  /// Returns the updated [AccountResponseDTO]
  /// 
  /// Throws:
  /// - [AccountNotFoundException] if the account doesn't exist
  /// - [ForbiddenException] if user doesn't have permission
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [ApiException] for other API errors
  Future<AccountResponseDTO> freezeAccount(String accountNumber);

  /// Unfreezes an account to allow transactions
  /// 
  /// [accountNumber] The account number to unfreeze
  /// 
  /// Returns the updated [AccountResponseDTO]
  /// 
  /// Throws:
  /// - [AccountNotFoundException] if the account doesn't exist
  /// - [ForbiddenException] if user doesn't have permission
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [ApiException] for other API errors
  Future<AccountResponseDTO> unfreezeAccount(String accountNumber);

  /// Retrieves accounts filtered by status
  /// 
  /// [status] The account status to filter by (ACTIVE, INACTIVE, DORMANT, BLOCKED)
  /// 
  /// Returns a list of [AccountListItemDTO] matching the status
  /// 
  /// Throws:
  /// - [BadRequestException] if status is invalid
  /// - [UnauthorizedException] if the user is not authenticated
  /// - [NetworkException] if there's a network connectivity issue
  /// - [ApiException] for other API errors
  Future<List<AccountListItemDTO>> getAccountsByStatus(String status);
}