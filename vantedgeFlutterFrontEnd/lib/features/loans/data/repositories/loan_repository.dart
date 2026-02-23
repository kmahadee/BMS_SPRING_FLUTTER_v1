import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';

import '../models/loan_model.dart';
import '../models/loan_application.dart';
import '../models/loan_statement.dart';
import '../models/loan_search.dart';
// import 'package:vantedge/features/accounts/data/models/transaction_history_model.dart';

/// Abstract repository interface for the Loan feature.
///
/// Mirrors every endpoint exposed by [LoanController] on the backend.
/// Implementations unwrap the `{ "success": true, "data": ... }` envelope
/// internally and return typed domain models.
///
/// HTTP verb note: approve and reject use POST (not PUT) — the Spring
/// controller uses @PostMapping for both. The OpenAPI doc is incorrect on
/// this point; the Java source is the source of truth.
///
/// Return-type note: repayLoan returns [TransactionHistoryModel] because
/// the backend returns a TransactionResponseDTO from its transaction
/// service, not a LoanResponseDTO.
abstract class LoanRepository {
  // ── Customer-facing endpoints ────────────────────────────────────────────

  /// `GET /api/loans/my-loans`
  ///
  /// Returns the authenticated customer's own loans in compact list form.
  /// Role: CUSTOMER.
  Future<List<LoanListItemModel>> getMyLoans();

  /// `GET /api/loans/{loanId}`
  ///
  /// Returns full detail for a single loan.
  /// Roles: CUSTOMER (own loans only), ADMIN, BRANCH_MANAGER,
  ///        LOAN_OFFICER, EMPLOYEE.
  Future<LoanResponseModel> getLoanById(String loanId);

  /// `GET /api/loans/{loanId}/statement`
  ///
  /// Returns the full loan statement including the complete repayment
  /// schedule and disbursement history.
  /// Roles: CUSTOMER (own), ADMIN, BRANCH_MANAGER, LOAN_OFFICER.
  Future<LoanStatementModel> getLoanStatement(String loanId);

  /// `POST /api/loans/apply`
  ///
  /// Submits a new loan application. Sends [LoanApplicationModel.toJson()]
  /// as the request body.
  /// Returns the created [LoanResponseModel] (HTTP 201).
  Future<LoanResponseModel> applyForLoan(LoanApplicationModel request);

  /// `POST /api/loans/{loanId}/repay`
  ///
  /// Processes an EMI / partial repayment for an active loan.
  /// The backend creates a ledger transaction and returns a
  /// [TransactionHistoryModel] (backend: TransactionResponseDTO).
  /// Returns HTTP 201.
  Future<TransactionHistoryModel> repayLoan(
    String loanId,
    LoanRepaymentRequestModel request,
  );

  /// `POST /api/loans/{loanId}/foreclose`
  ///
  /// Initiates early loan closure. Returns the updated [LoanResponseModel].
  /// Roles: CUSTOMER (own), ADMIN, BRANCH_MANAGER, LOAN_OFFICER.
  Future<LoanResponseModel> forecloseLoan(
    String loanId,
    LoanForeclosureRequestModel request,
  );

  // ── Staff / officer / admin endpoints ────────────────────────────────────

  /// `GET /api/loans/pending-approval`
  ///
  /// Returns all loans awaiting an approval decision.
  /// Roles: ADMIN, BRANCH_MANAGER, LOAN_OFFICER.
  Future<List<LoanListItemModel>> getPendingApprovalLoans();

  /// `GET /api/loans/customer/{customerId}`
  ///
  /// Returns all loans belonging to a specific customer (staff view).
  /// Roles: ADMIN, BRANCH_MANAGER, LOAN_OFFICER.
  Future<List<LoanListItemModel>> getLoansByCustomerId(String customerId);

  /// `GET /api/loans?pageNumber=&pageSize=`
  ///
  /// Returns a paginated snapshot of all loans.
  /// Roles: ADMIN, BRANCH_MANAGER, LOAN_OFFICER.
  Future<LoanSearchResponseModel> getAllLoans({
    int pageNumber = 1,
    int pageSize = 10,
  });

  /// `POST /api/loans/search`
  ///
  /// Searches loans with optional filters (customerId, loanStatus, loanType)
  /// and pagination. Sends [LoanSearchRequestModel.toJson()] as POST body.
  /// Roles: ADMIN, BRANCH_MANAGER, LOAN_OFFICER.
  Future<LoanSearchResponseModel> searchLoans(LoanSearchRequestModel request);

  /// `POST /api/loans/{loanId}/approve`
  ///
  /// Approves a pending loan application.
  /// The backend overwrites approvalStatus = "APPROVED" server-side.
  /// Roles: ADMIN, EMPLOYEE, BRANCH_MANAGER.
  Future<LoanResponseModel> approveLoan(
    String loanId,
    LoanApprovalRequestModel request,
  );

  /// `POST /api/loans/{loanId}/reject`
  ///
  /// Rejects a pending loan application.
  /// The backend overwrites approvalStatus = "REJECTED" server-side.
  /// Roles: ADMIN, EMPLOYEE, BRANCH_MANAGER.
  Future<LoanResponseModel> rejectLoan(
    String loanId,
    LoanApprovalRequestModel request,
  );

  /// `POST /api/loans/{loanId}/disburse`
  ///
  /// Disburses an approved loan to the specified account.
  /// Roles: ADMIN, EMPLOYEE, BRANCH_MANAGER.
  Future<LoanResponseModel> disburseLoan(
    String loanId,
    LoanDisbursementRequestModel request,
  );
}
