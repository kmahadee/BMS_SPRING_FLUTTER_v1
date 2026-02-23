enum LoanType {
  homeLoan,
  carLoan,
  personalLoan,
  educationLoan,
  businessLoan,
  goldLoan,
  industrialLoan,
  importLcLoan,
  workingCapitalLoan;

  static LoanType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'HOME_LOAN':
        return LoanType.homeLoan;
      case 'CAR_LOAN':
        return LoanType.carLoan;
      case 'PERSONAL_LOAN':
        return LoanType.personalLoan;
      case 'EDUCATION_LOAN':
        return LoanType.educationLoan;
      case 'BUSINESS_LOAN':
        return LoanType.businessLoan;
      case 'GOLD_LOAN':
        return LoanType.goldLoan;
      case 'INDUSTRIAL_LOAN':
        return LoanType.industrialLoan;
      case 'IMPORT_LC_LOAN':
        return LoanType.importLcLoan;
      case 'WORKING_CAPITAL_LOAN':
        return LoanType.workingCapitalLoan;
      default:
        throw ArgumentError('Unknown LoanType: $value');
    }
  }

  String toApiString() {
    switch (this) {
      case LoanType.homeLoan:
        return 'HOME_LOAN';
      case LoanType.carLoan:
        return 'CAR_LOAN';
      case LoanType.personalLoan:
        return 'PERSONAL_LOAN';
      case LoanType.educationLoan:
        return 'EDUCATION_LOAN';
      case LoanType.businessLoan:
        return 'BUSINESS_LOAN';
      case LoanType.goldLoan:
        return 'GOLD_LOAN';
      case LoanType.industrialLoan:
        return 'INDUSTRIAL_LOAN';
      case LoanType.importLcLoan:
        return 'IMPORT_LC_LOAN';
      case LoanType.workingCapitalLoan:
        return 'WORKING_CAPITAL_LOAN';
    }
  }

  String get displayName {
    switch (this) {
      case LoanType.homeLoan:
        return 'Home Loan';
      case LoanType.carLoan:
        return 'Car Loan';
      case LoanType.personalLoan:
        return 'Personal Loan';
      case LoanType.educationLoan:
        return 'Education Loan';
      case LoanType.businessLoan:
        return 'Business Loan';
      case LoanType.goldLoan:
        return 'Gold Loan';
      case LoanType.industrialLoan:
        return 'Industrial Loan';
      case LoanType.importLcLoan:
        return 'Import LC Loan';
      case LoanType.workingCapitalLoan:
        return 'Working Capital Loan';
    }
  }
}

// ---------------------------------------------------------------------------

enum LoanStatus {
  application,
  processing,
  approved,
  active,
  closed,
  defaulted;

  static LoanStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'APPLICATION':
        return LoanStatus.application;
      case 'PROCESSING':
        return LoanStatus.processing;
      case 'APPROVED':
        return LoanStatus.approved;
      case 'ACTIVE':
        return LoanStatus.active;
      case 'CLOSED':
        return LoanStatus.closed;
      case 'DEFAULTED':
        return LoanStatus.defaulted;
      default:
        throw ArgumentError('Unknown LoanStatus: $value');
    }
  }

  String toApiString() {
    switch (this) {
      case LoanStatus.application:
        return 'APPLICATION';
      case LoanStatus.processing:
        return 'PROCESSING';
      case LoanStatus.approved:
        return 'APPROVED';
      case LoanStatus.active:
        return 'ACTIVE';
      case LoanStatus.closed:
        return 'CLOSED';
      case LoanStatus.defaulted:
        return 'DEFAULTED';
    }
  }

  String get displayName {
    switch (this) {
      case LoanStatus.application:
        return 'Application';
      case LoanStatus.processing:
        return 'Processing';
      case LoanStatus.approved:
        return 'Approved';
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.closed:
        return 'Closed';
      case LoanStatus.defaulted:
        return 'Defaulted';
    }
  }

  bool get isActive => this == LoanStatus.active;
  bool get isClosed => this == LoanStatus.closed || this == LoanStatus.defaulted;
  bool get isPending => this == LoanStatus.application || this == LoanStatus.processing;
}

// ---------------------------------------------------------------------------

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  static ApprovalStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return ApprovalStatus.pending;
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'REJECTED':
        return ApprovalStatus.rejected;
      default:
        throw ArgumentError('Unknown ApprovalStatus: $value');
    }
  }

  String toApiString() {
    switch (this) {
      case ApprovalStatus.pending:
        return 'PENDING';
      case ApprovalStatus.approved:
        return 'APPROVED';
      case ApprovalStatus.rejected:
        return 'REJECTED';
    }
  }

  String get displayName {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

// ---------------------------------------------------------------------------

enum DisbursementStatus {
  pending,
  scheduled,
  completed,
  failed;

  static DisbursementStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return DisbursementStatus.pending;
      case 'SCHEDULED':
        return DisbursementStatus.scheduled;
      case 'COMPLETED':
        return DisbursementStatus.completed;
      case 'FAILED':
        return DisbursementStatus.failed;
      default:
        throw ArgumentError('Unknown DisbursementStatus: $value');
    }
  }

  String toApiString() {
    switch (this) {
      case DisbursementStatus.pending:
        return 'PENDING';
      case DisbursementStatus.scheduled:
        return 'SCHEDULED';
      case DisbursementStatus.completed:
        return 'COMPLETED';
      case DisbursementStatus.failed:
        return 'FAILED';
    }
  }

  String get displayName {
    switch (this) {
      case DisbursementStatus.pending:
        return 'Pending';
      case DisbursementStatus.scheduled:
        return 'Scheduled';
      case DisbursementStatus.completed:
        return 'Completed';
      case DisbursementStatus.failed:
        return 'Failed';
    }
  }
}

// ---------------------------------------------------------------------------

enum ApplicantType {
  individual,
  corporate;

  static ApplicantType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INDIVIDUAL':
        return ApplicantType.individual;
      case 'CORPORATE':
        return ApplicantType.corporate;
      default:
        throw ArgumentError('Unknown ApplicantType: $value');
    }
  }

  String toApiString() {
    switch (this) {
      case ApplicantType.individual:
        return 'INDIVIDUAL';
      case ApplicantType.corporate:
        return 'CORPORATE';
    }
  }

  String get displayName {
    switch (this) {
      case ApplicantType.individual:
        return 'Individual';
      case ApplicantType.corporate:
        return 'Corporate';
    }
  }
}

// ---------------------------------------------------------------------------

enum ScheduleStatus {
  pending,
  paid,
  overdue,
  partial;

  static ScheduleStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return ScheduleStatus.pending;
      case 'PAID':
        return ScheduleStatus.paid;
      case 'OVERDUE':
        return ScheduleStatus.overdue;
      case 'PARTIAL':
        return ScheduleStatus.partial;
      default:
        return ScheduleStatus.pending; // graceful fallback
    }
  }

  String toApiString() {
    switch (this) {
      case ScheduleStatus.pending:
        return 'PENDING';
      case ScheduleStatus.paid:
        return 'PAID';
      case ScheduleStatus.overdue:
        return 'OVERDUE';
      case ScheduleStatus.partial:
        return 'PARTIAL';
    }
  }

  String get displayName {
    switch (this) {
      case ScheduleStatus.pending:
        return 'Pending';
      case ScheduleStatus.paid:
        return 'Paid';
      case ScheduleStatus.overdue:
        return 'Overdue';
      case ScheduleStatus.partial:
        return 'Partial';
    }
  }

  bool get isPaid => this == ScheduleStatus.paid;
  bool get isOverdue => this == ScheduleStatus.overdue;
}

// ---------------------------------------------------------------------------

enum EmploymentType {
  salaried,
  selfEmployed,
  business;

  static EmploymentType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SALARIED':
        return EmploymentType.salaried;
      case 'SELF_EMPLOYED':
        return EmploymentType.selfEmployed;
      case 'BUSINESS':
        return EmploymentType.business;
      default:
        throw ArgumentError('Unknown EmploymentType: $value');
    }
  }

  String toApiString() {
    switch (this) {
      case EmploymentType.salaried:
        return 'SALARIED';
      case EmploymentType.selfEmployed:
        return 'SELF_EMPLOYED';
      case EmploymentType.business:
        return 'BUSINESS';
    }
  }

  String get displayName {
    switch (this) {
      case EmploymentType.salaried:
        return 'Salaried';
      case EmploymentType.selfEmployed:
        return 'Self Employed';
      case EmploymentType.business:
        return 'Business';
    }
  }
}

// ---------------------------------------------------------------------------

enum LoanPaymentMode {
  cash,
  cheque,
  neft,
  imps;

  static LoanPaymentMode fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CASH':
        return LoanPaymentMode.cash;
      case 'CHEQUE':
        return LoanPaymentMode.cheque;
      case 'NEFT':
        return LoanPaymentMode.neft;
      case 'IMPS':
        return LoanPaymentMode.imps;
      default:
        throw ArgumentError('Unknown LoanPaymentMode: $value');
    }
  }

  String toApiString() {
    switch (this) {
      case LoanPaymentMode.cash:
        return 'CASH';
      case LoanPaymentMode.cheque:
        return 'CHEQUE';
      case LoanPaymentMode.neft:
        return 'NEFT';
      case LoanPaymentMode.imps:
        return 'IMPS';
    }
  }

  String get displayName {
    switch (this) {
      case LoanPaymentMode.cash:
        return 'Cash';
      case LoanPaymentMode.cheque:
        return 'Cheque';
      case LoanPaymentMode.neft:
        return 'NEFT';
      case LoanPaymentMode.imps:
        return 'IMPS';
    }
  }
}
