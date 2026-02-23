import 'package:flutter/material.dart';
import 'package:vantedge/features/loans/data/models/loan_enums.dart';

// ─── LoanType display helpers ────────────────────────────────────────────────

extension LoanTypeDisplay on LoanType {
  IconData get icon {
    switch (this) {
      case LoanType.homeLoan:
        return Icons.home_rounded;
      case LoanType.carLoan:
        return Icons.directions_car_rounded;
      case LoanType.personalLoan:
        return Icons.person_rounded;
      case LoanType.educationLoan:
        return Icons.school_rounded;
      case LoanType.businessLoan:
        return Icons.business_center_rounded;
      case LoanType.goldLoan:
        return Icons.workspace_premium_rounded;
      case LoanType.industrialLoan:
        return Icons.factory_rounded;
      case LoanType.importLcLoan:
        return Icons.local_shipping_rounded;
      case LoanType.workingCapitalLoan:
        return Icons.account_balance_wallet_rounded;
    }
  }

  /// Accent color representing the loan type (light-theme friendly).
  Color get color {
    switch (this) {
      case LoanType.homeLoan:
        return const Color(0xFF1565C0); // blue 800
      case LoanType.carLoan:
        return const Color(0xFF6A1B9A); // purple 800
      case LoanType.personalLoan:
        return const Color(0xFF00695C); // teal 800
      case LoanType.educationLoan:
        return const Color(0xFF2E7D32); // green 800
      case LoanType.businessLoan:
        return const Color(0xFFF57F17); // amber 900
      case LoanType.goldLoan:
        return const Color(0xFFC79100); // gold-ish
      case LoanType.industrialLoan:
        return const Color(0xFF37474F); // blue-grey 800
      case LoanType.importLcLoan:
        return const Color(0xFFBF360C); // deep-orange 900
      case LoanType.workingCapitalLoan:
        return const Color(0xFF4527A0); // deep-purple 800
    }
  }

  /// Container (background) color for chips / cards.
  Color get containerColor => color.withOpacity(0.12);

  /// On-container text / icon color.
  Color get onContainerColor => color;
}

// ─── LoanStatus display helpers ──────────────────────────────────────────────

extension LoanStatusDisplay on LoanStatus {
  IconData get icon {
    switch (this) {
      case LoanStatus.application:
        return Icons.assignment_rounded;
      case LoanStatus.processing:
        return Icons.hourglass_top_rounded;
      case LoanStatus.approved:
        return Icons.check_circle_rounded;
      case LoanStatus.active:
        return Icons.play_circle_filled_rounded;
      case LoanStatus.closed:
        return Icons.lock_rounded;
      case LoanStatus.defaulted:
        return Icons.warning_rounded;
    }
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case LoanStatus.application:
        return const Color(0xFFEEEEEE); // grey 200
      case LoanStatus.processing:
        return const Color(0xFFBBDEFB); // blue 100
      case LoanStatus.approved:
        return const Color(0xFFC8E6C9); // green 100
      case LoanStatus.active:
        return const Color(0xFFB2DFDB); // teal 100
      case LoanStatus.closed:
        return const Color(0xFFE0E0E0); // grey 300
      case LoanStatus.defaulted:
        return const Color(0xFFFFCDD2); // red 100
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case LoanStatus.application:
        return const Color(0xFF616161); // grey 700
      case LoanStatus.processing:
        return const Color(0xFF1565C0); // blue 800
      case LoanStatus.approved:
        return const Color(0xFF2E7D32); // green 800
      case LoanStatus.active:
        return const Color(0xFF00695C); // teal 800
      case LoanStatus.closed:
        return const Color(0xFF424242); // grey 800
      case LoanStatus.defaulted:
        return const Color(0xFFC62828); // red 800
    }
  }

  String get semanticDescription {
    switch (this) {
      case LoanStatus.application:
        return 'Loan application submitted, awaiting review';
      case LoanStatus.processing:
        return 'Loan is being reviewed and processed';
      case LoanStatus.approved:
        return 'Loan approved, pending disbursement';
      case LoanStatus.active:
        return 'Loan is active with ongoing EMIs';
      case LoanStatus.closed:
        return 'Loan has been fully repaid and closed';
      case LoanStatus.defaulted:
        return 'Loan is in default status';
    }
  }
}
