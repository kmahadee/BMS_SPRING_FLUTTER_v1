import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/constants/api_constants.dart';
// import '../../../../core/network/dio_client.dart';
// import '../../../../core/network/api_constants.dart';

/// Service for dashboard-related data aggregation
/// This service calls multiple existing endpoints and calculates statistics locally
class DashboardService {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  DashboardService({required DioClient dioClient}) : _dioClient = dioClient;

  /// Get customer account summary
  /// Calls GET /api/accounts and filters by customer
  Future<Map<String, dynamic>> getCustomerAccountsSummary(String customerId) async {
    try {
      _logger.d('Fetching accounts summary for customer: $customerId');
      
      final response = await _dioClient.get(ApiConstants.getAllAccounts);

      if (response.data['success'] == true) {
        final allAccounts = (response.data['data'] as List?) ?? [];
        
        // Filter accounts by customer ID
        final customerAccounts = allAccounts
            .where((account) => account['customerId'] == customerId)
            .toList();
        
        // Calculate total balance
        double totalBalance = 0.0;
        for (var account in customerAccounts) {
          totalBalance += (account['balance'] as num?)?.toDouble() ?? 0.0;
        }

        return {
          'totalBalance': totalBalance,
          'accountCount': customerAccounts.length,
          'accounts': customerAccounts,
        };
      }

      throw Exception('Failed to fetch accounts summary');
    } on DioException catch (e) {
      _logger.e('Error fetching accounts summary: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error fetching accounts summary: $e');
      rethrow;
    }
  }

  /// Get all accounts (for branch manager/admin)
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    try {
      _logger.d('Fetching all accounts');
      
      final response = await _dioClient.get(ApiConstants.getAllAccounts);

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }

      throw Exception('Failed to fetch accounts');
    } on DioException catch (e) {
      _logger.e('Error fetching accounts: ${e.message}');
      rethrow;
    }
  }

  /// Calculate branch statistics from accounts data
  Future<Map<String, dynamic>> calculateBranchStatistics(int branchId) async {
    try {
      _logger.d('Calculating branch statistics for branch: $branchId');

      // Get all accounts
      final accounts = await getAllAccounts();
      
      // Filter by branch
      final branchAccounts = accounts
          .where((account) => account['branchId'] == branchId)
          .toList();

      // Calculate totals
      double totalDeposits = 0.0;
      for (var account in branchAccounts) {
        final balance = (account['balance'] as num?)?.toDouble() ?? 0.0;
        if (balance > 0) {
          totalDeposits += balance;
        }
      }

      // Get active accounts (assuming ACTIVE status)
      final activeAccounts = branchAccounts
          .where((account) => account['status'] == 'ACTIVE')
          .toList();

      return {
        'totalAccounts': branchAccounts.length,
        'activeAccounts': activeAccounts.length,
        'totalDeposits': totalDeposits,
        'branchId': branchId,
      };
    } catch (e) {
      _logger.e('Error calculating branch statistics: $e');
      rethrow;
    }
  }

  /// Calculate bank-wide statistics
  Future<Map<String, dynamic>> calculateBankStatistics() async {
    try {
      _logger.d('Calculating bank-wide statistics');

      // Get all data in parallel
      final results = await Future.wait([
        getAllAccounts(),
        getAllCustomers(),
        getAllLoans(),
        getAllCards(),
        getAllBranches(),
      ]);

      final accounts = results[0];
      final customers = results[1];
      final loans = results[2];
      final cards = results[3];
      final branches = results[4];

      // Calculate account statistics
      double totalDeposits = 0.0;
      int activeAccounts = 0;
      for (var account in accounts) {
        final balance = (account['balance'] as num?)?.toDouble() ?? 0.0;
        totalDeposits += balance;
        if (account['status'] == 'ACTIVE') activeAccounts++;
      }

      // Calculate loan statistics
      int activeLoans = 0;
      double totalLoanAmount = 0.0;
      for (var loan in loans) {
        if (loan['loanStatus'] == 'ACTIVE' || loan['loanStatus'] == 'DISBURSED') {
          activeLoans++;
          totalLoanAmount += (loan['outstandingBalance'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Calculate card statistics
      int activeCards = cards.where((card) => card['status'] == 'ACTIVE').length;

      // Calculate branch statistics
      int activeBranches = branches.where((branch) => branch['status'] == 'ACTIVE').length;

      return {
        'totalAccounts': accounts.length,
        'activeAccounts': activeAccounts,
        'totalCustomers': customers.length,
        'totalDeposits': totalDeposits,
        'activeLoans': activeLoans,
        'totalLoanAmount': totalLoanAmount,
        'activeCards': activeCards,
        'totalBranches': branches.length,
        'activeBranches': activeBranches,
      };
    } catch (e) {
      _logger.e('Error calculating bank statistics: $e');
      rethrow;
    }
  }

  /// Get all customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      _logger.d('Fetching all customers');
      
      final response = await _dioClient.get(ApiConstants.getAllCustomers);

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }

      throw Exception('Failed to fetch customers');
    } on DioException catch (e) {
      _logger.e('Error fetching customers: ${e.message}');
      rethrow;
    }
  }

  /// Get all loans
  Future<List<Map<String, dynamic>>> getAllLoans() async {
    try {
      _logger.d('Fetching all loans');
      
      // Note: This endpoint has pagination, so we fetch first page
      // For production, you might want to implement pagination
      final response = await _dioClient.get(
        ApiConstants.getAllLoans,
        queryParameters: {
          'pageNumber': 1,
          'pageSize': 1000, // Get a large page to get most loans
        },
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }

      throw Exception('Failed to fetch loans');
    } on DioException catch (e) {
      _logger.e('Error fetching loans: ${e.message}');
      rethrow;
    }
  }

  /// Calculate loan officer statistics
  Future<Map<String, dynamic>> calculateLoanStatistics() async {
    try {
      _logger.d('Calculating loan statistics');

      final loans = await getAllLoans();

      int pending = 0;
      int approved = 0;
      int disbursed = 0;
      int rejected = 0;
      double totalDisbursed = 0.0;
      double totalOutstanding = 0.0;

      for (var loan in loans) {
        final approvalStatus = loan['approvalStatus']?.toString().toUpperCase();
        final loanStatus = loan['loanStatus']?.toString().toUpperCase();

        // Count by approval status
        if (approvalStatus == 'PENDING') {
          pending++;
        } else if (approvalStatus == 'APPROVED') {
          approved++;
        } else if (approvalStatus == 'REJECTED') {
          rejected++;
        }

        // Count disbursed and calculate amounts
        if (loanStatus == 'DISBURSED' || loanStatus == 'ACTIVE') {
          disbursed++;
          totalDisbursed += (loan['principal'] as num?)?.toDouble() ?? 0.0;
          totalOutstanding += (loan['outstandingBalance'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'totalLoans': loans.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'disbursed': disbursed,
        'totalDisbursed': totalDisbursed,
        'totalOutstanding': totalOutstanding,
      };
    } catch (e) {
      _logger.e('Error calculating loan statistics: $e');
      rethrow;
    }
  }

  /// Get all cards
  Future<List<Map<String, dynamic>>> getAllCards() async {
    try {
      _logger.d('Fetching all cards');
      
      final response = await _dioClient.get(ApiConstants.getAllCards);

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }

      throw Exception('Failed to fetch cards');
    } on DioException catch (e) {
      _logger.e('Error fetching cards: ${e.message}');
      rethrow;
    }
  }

  /// Calculate card officer statistics
  Future<Map<String, dynamic>> calculateCardStatistics() async {
    try {
      _logger.d('Calculating card statistics');

      final cards = await getAllCards();

      int pending = 0;
      int active = 0;
      int blocked = 0;
      int expired = 0;
      int issuedThisMonth = 0;
      double totalCreditLimit = 0.0;
      double totalAvailableLimit = 0.0;

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (var card in cards) {
        final status = card['status']?.toString().toUpperCase();

        // Count by status
        if (status == 'PENDING') {
          pending++;
        } else if (status == 'ACTIVE') {
          active++;
          totalCreditLimit += (card['creditLimit'] as num?)?.toDouble() ?? 0.0;
          totalAvailableLimit += (card['availableLimit'] as num?)?.toDouble() ?? 0.0;
        } else if (status == 'BLOCKED') {
          blocked++;
        } else if (status == 'EXPIRED') {
          expired++;
        }

        // Check if issued this month (if there's an issueDate field)
        final issueDateStr = card['issueDate'] as String?;
        if (issueDateStr != null) {
          try {
            final issueDate = DateTime.parse(issueDateStr);
            if (issueDate.isAfter(firstDayOfMonth)) {
              issuedThisMonth++;
            }
          } catch (e) {
            _logger.w('Failed to parse issue date: $issueDateStr');
          }
        }
      }

      return {
        'totalCards': cards.length,
        'pending': pending,
        'active': active,
        'blocked': blocked,
        'expired': expired,
        'issuedThisMonth': issuedThisMonth,
        'totalCreditLimit': totalCreditLimit,
        'totalAvailableLimit': totalAvailableLimit,
      };
    } catch (e) {
      _logger.e('Error calculating card statistics: $e');
      rethrow;
    }
  }

  /// Get all branches
  Future<List<Map<String, dynamic>>> getAllBranches() async {
    try {
      _logger.d('Fetching all branches');
      
      final response = await _dioClient.get(ApiConstants.getAllBranches);

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }

      throw Exception('Failed to fetch branches');
    } on DioException catch (e) {
      _logger.e('Error fetching branches: ${e.message}');
      rethrow;
    }
  }

  /// Get customer's cards
  Future<List<Map<String, dynamic>>> getCustomerCards(String customerId) async {
    try {
      _logger.d('Fetching cards for customer: $customerId');
      
      final allCards = await getAllCards();
      
      // Filter by customer ID
      return allCards
          .where((card) => card['customerId'] == customerId)
          .toList();
    } catch (e) {
      _logger.e('Error fetching customer cards: $e');
      rethrow;
    }
  }

  /// Get customer's loans
  Future<List<Map<String, dynamic>>> getCustomerLoans(String customerId) async {
    try {
      _logger.d('Fetching loans for customer: $customerId');
      
      final allLoans = await getAllLoans();
      
      // Filter by customer ID
      return allLoans
          .where((loan) => loan['customerId'] == customerId)
          .toList();
    } catch (e) {
      _logger.e('Error fetching customer loans: $e');
      rethrow;
    }
  }
}