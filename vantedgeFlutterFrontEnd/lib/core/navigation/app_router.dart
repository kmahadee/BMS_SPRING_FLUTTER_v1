// lib/core/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/di/service_locator.dart';
import 'package:vantedge/features/accounts/presentation/presentation/screens/account_details_screen.dart';
import 'package:vantedge/features/accounts/presentation/presentation/screens/account_list_screen.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/core/navigation/route_guard.dart';

// Auth screens
import 'package:vantedge/features/auth/presentation/screens/customer_signup_screen.dart';
import 'package:vantedge/features/auth/presentation/screens/login_screen.dart';
import 'package:vantedge/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:vantedge/features/auth/presentation/screens/splash_screen.dart';
import 'package:vantedge/features/branches/data/repositories/branch_repository_impl.dart';
import 'package:vantedge/features/branches/presentation/providers/branch_provider.dart';
import 'package:vantedge/features/branches/presentation/screens/branch_list_screen.dart';

// Home screens
import 'package:vantedge/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:vantedge/features/dps/data/models/dps_repository.dart';
import 'package:vantedge/features/dps/presentation/providers/dps_provider.dart';
import 'package:vantedge/features/dps/presentation/screens/dps_create_screen.dart';
import 'package:vantedge/features/dps/presentation/screens/dps_details_screen.dart';
import 'package:vantedge/features/dps/presentation/screens/dps_list_screen.dart';
import 'package:vantedge/features/dps/presentation/screens/installment_history_screen.dart';
import 'package:vantedge/features/dps/presentation/screens/maturity_calculator_screen.dart';
import 'package:vantedge/features/dps/presentation/screens/pay_installment_screen.dart';
import 'package:vantedge/features/home/presentation/screens/customer_home_screen.dart';

// Transaction screens
import 'package:vantedge/features/transactions/presentation/screens/transaction_home_screen.dart';
import 'package:vantedge/features/transactions/presentation/screens/deposit_screen.dart';
import 'package:vantedge/features/transactions/presentation/screens/withdraw_screen.dart';
import 'package:vantedge/features/transactions/presentation/screens/transfer_screen.dart';
import 'package:vantedge/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:vantedge/features/transactions/presentation/screens/transaction_details_screen.dart';
import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';

// ── Loan screens ──────────────────────────────────────────────────────────────
import 'package:vantedge/features/loans/presentation/screens/loan_list_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/loan_application_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/loan_details_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/repayment_schedule_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/loan_payment_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/officer_loan_queue_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/loan_approval_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/loan_disbursement_screen.dart';
import 'package:vantedge/features/loans/presentation/screens/loan_search_screen.dart';
// ─────────────────────────────────────────────────────────────────────────────

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // ── Auth ─────────────────────────────────────────────────────────────
      case AppRoutes.login:
        return _buildRoute(settings, _getLoginScreen());

      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const SplashScreen(),
        );

      case AppRoutes.onboarding:
        return _buildRoute(settings, const OnboardingScreen());

      case AppRoutes.signup:
        return _buildRoute(settings, _getSignupScreen());

      case AppRoutes.forgotPassword:
        return _buildRoute(settings, _getForgotPasswordScreen());

      // ── Home ─────────────────────────────────────────────────────────────
      case AppRoutes.home:
      case AppRoutes.customerHome:
      case AppRoutes.branchManagerHome:
      case AppRoutes.loanOfficerHome:
      case AppRoutes.cardOfficerHome:
      case AppRoutes.adminHome:
      case AppRoutes.superAdminHome:
      case AppRoutes.employeeHome:
        return _buildRoute(
          settings,
          _getHomeScreen(settings.name!),
          requireAuth: true,
        );

      // ── Accounts ─────────────────────────────────────────────────────────
      case AppRoutes.accounts:
        return _buildRoute(settings, _getAccountsScreen(), requireAuth: true);

      case AppRoutes.accountDetails:
        return _buildRoute(
          settings,
          _getAccountDetailsScreen(args),
          requireAuth: true,
        );

      // ── Transactions ──────────────────────────────────────────────────────
      case AppRoutes.transactions:
        return _buildRoute(
          settings,
          const TransactionHomeScreen(),
          requireAuth: true,
        );

      case AppRoutes.transactionDetails:
        final txn = args is TransactionHistoryModel ? args : null;
        if (txn == null) return _buildRoute(settings, _get404Screen());
        return _buildRoute(
          settings,
          TransactionDetailsScreen(transaction: txn),
          requireAuth: true,
        );

      case AppRoutes.transfer:
        return _buildRoute(settings, const TransferScreen(), requireAuth: true);

      case AppRoutes.deposit:
        final depositAcct = args is String ? args : null;
        return _buildRoute(
          settings,
          DepositScreen(preselectedAccountNumber: depositAcct),
          requireAuth: true,
        );

      case AppRoutes.withdrawal:
        final withdrawAcct = args is String ? args : null;
        return _buildRoute(
          settings,
          WithdrawScreen(preselectedAccountNumber: withdrawAcct),
          requireAuth: true,
        );

      case AppRoutes.transactionHistory:
        final historyAcct = args is String ? args : null;
        return _buildRoute(
          settings,
          TransactionHistoryScreen(accountNumber: historyAcct),
          requireAuth: true,
        );

      // ── Customer-facing loan routes ────────────────────────────────────────

      /// /loans — list of the logged-in customer's loans.
      case AppRoutes.loans:
        return _buildRoute(settings, const LoanListScreen(), requireAuth: true);

      /// /loans/apply — loan application form.
      case AppRoutes.loanApplication:
        return _buildRoute(
          settings,
          const LoanApplicationScreen(),
          requireAuth: true,
        );

      /// /loans/details — loan detail view; expects loanId (String) as argument.
      case AppRoutes.loanDetails:
        final loanId = args is String ? args : null;
        if (loanId == null) return _buildRoute(settings, _get404Screen());
        return _buildRoute(
          settings,
          LoanDetailsScreen(loanId: loanId),
          requireAuth: true,
        );

      /// /loans/schedule — repayment schedule; expects loanId (String) as argument.
      case AppRoutes.loanRepaymentSchedule:
        final loanId = args is String ? args : null;
        if (loanId == null) return _buildRoute(settings, _get404Screen());
        return _buildRoute(
          settings,
          RepaymentScheduleScreen(loanId: loanId),
          requireAuth: true,
        );

      /// /loans/pay — make a payment; expects loanId (String) as argument.
      case AppRoutes.loanPayment:
        final loanId = args is String ? args : null;
        if (loanId == null) return _buildRoute(settings, _get404Screen());
        return _buildRoute(
          settings,
          LoanPaymentScreen(loanId: loanId),
          requireAuth: true,
        );

      // ── Officer-only loan routes (role-guarded) ────────────────────────────

      /// /officer/loans — pending-approval queue.
      /// Also handles the legacy /loans/approval path used in drawers/nav bars.
      case AppRoutes.officerLoanQueue:
      case AppRoutes.loanApproval: // legacy alias — still usable from drawer
        return _buildRoute(
          settings,
          const OfficerLoanQueueScreen(),
          requireAuth: true,
        );

      /// /officer/loans/approve — review & approve/reject a loan.
      /// Also handles the legacy /loans/applications path.
      case AppRoutes.officerLoanApprove:
      case AppRoutes.loanApplications: // legacy alias
        final loanId = args is String ? args : null;
        if (loanId == null) {
          // No loanId → fall through to the queue
          return _buildRoute(
            settings,
            const OfficerLoanQueueScreen(),
            requireAuth: true,
          );
        }
        return _buildRoute(
          settings,
          LoanApprovalScreen(loanId: loanId),
          requireAuth: true,
        );

      /// /officer/loans/disburse — disburse an approved loan.
      case AppRoutes.officerLoanDisburse:
        final loanId = args is String ? args : null;
        if (loanId == null) return _buildRoute(settings, _get404Screen());
        return _buildRoute(
          settings,
          LoanDisbursementScreen(loanId: loanId),
          requireAuth: true,
        );

      /// /officer/loans/search — advanced loan search.
      case AppRoutes.officerLoanSearch:
        return _buildRoute(
          settings,
          const LoanSearchScreen(),
          requireAuth: true,
        );

      //-----DPS --------------------

      // case AppRoutes.dps:
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => const DpsListScreen(),
      //   );

      // case AppRoutes.dpsDetails:
      //   final dpsNumber = settings.arguments as String? ?? '';
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => DpsDetailsScreen(dpsNumber: dpsNumber),
      //   );

      // case AppRoutes.dpsCreate:
      //   // Accept optional pre-fill values from the maturity calculator.
      //   final args = settings.arguments as Map<String, dynamic>?;
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => DpsCreateScreen(
      //       initialInstallment: args?['initialInstallment'] as double?,
      //       initialTenure: args?['initialTenure'] as int?,
      //       initialRate: args?['initialRate'] as double?,
      //     ),
      //   );

      // case AppRoutes.dpsInstallments:
      //   final dpsNumber = settings.arguments as String? ?? '';
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => InstallmentHistoryScreen(dpsNumber: dpsNumber),
      //   );

      // case AppRoutes.dpsPay:
      //   final dpsNumber = settings.arguments as String? ?? '';
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => PayInstallmentScreen(dpsNumber: dpsNumber),
      //   );

      // case AppRoutes.dpsCalculator:
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => const MaturityCalculatorScreen(),
      //   );

      case AppRoutes.dps:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) =>
                DpsProvider(repository: DpsRepository(dioClient: DioClient())),
            child: const DpsListScreen(),
          ),
        );

      case AppRoutes.dpsDetails:
        final dpsNumber = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) =>
                DpsProvider(repository: DpsRepository(dioClient: DioClient())),
            child: DpsDetailsScreen(dpsNumber: dpsNumber),
          ),
        );

      case AppRoutes.dpsCreate:
        final dpsCreateArgs = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) =>
                DpsProvider(repository: DpsRepository(dioClient: DioClient())),
            child: DpsCreateScreen(
              initialInstallment:
                  dpsCreateArgs?['initialInstallment'] as double?,
              initialTenure: dpsCreateArgs?['initialTenure'] as int?,
              initialRate: dpsCreateArgs?['initialRate'] as double?,
            ),
          ),
        );

      // case AppRoutes.dpsCreate:
      //   final dpsCreateArgs = settings.arguments as Map<String, dynamic>?;
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => MultiProvider(
      //       providers: [
      //         ChangeNotifierProvider(
      //           create: (_) =>
      //               DpsProvider(repository: DpsRepository(dioClient: DioClient())),
      //         ),
      //         ChangeNotifierProvider(
      //           create: (_) => BranchProvider(
      //             repository: BranchRepositoryImpl(dioClient: DioClient()),
      //           ),
      //         ),
      //       ],
      //       child: DpsCreateScreen(
      //         initialInstallment:
      //             dpsCreateArgs?['initialInstallment'] as double?,
      //         initialTenure: dpsCreateArgs?['initialTenure'] as int?,
      //         initialRate: dpsCreateArgs?['initialRate'] as double?,
      //       ),
      //     ),
      //   );

      case AppRoutes.dpsInstallments:
        final dpsNumber = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) =>
                DpsProvider(repository: DpsRepository(dioClient: DioClient())),
            child: InstallmentHistoryScreen(dpsNumber: dpsNumber),
          ),
        );

      case AppRoutes.dpsPay:
        final dpsNumber = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) =>
                DpsProvider(repository: DpsRepository(dioClient: DioClient())),
            child: PayInstallmentScreen(dpsNumber: dpsNumber),
          ),
        );

      case AppRoutes.dpsCalculator:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) =>
                DpsProvider(repository: DpsRepository(dioClient: DioClient())),
            child: const MaturityCalculatorScreen(),
          ),
        );

      // ── Misc ──────────────────────────────────────────────────────────────
      case AppRoutes.branchManagement:
        return _buildRoute(settings, _getBranchListScreen(), requireAuth: true);

      case AppRoutes.profile:
        return _buildRoute(settings, _getProfileScreen(), requireAuth: true);

      case AppRoutes.settings:
        return _buildRoute(settings, _getSettingsScreen(), requireAuth: true);

      case AppRoutes.notifications:
        return _buildRoute(
          settings,
          _getNotificationsScreen(),
          requireAuth: true,
        );

      case AppRoutes.error404:
        return _buildRoute(settings, _get404Screen());

      default:
        return _buildRoute(settings, _get404Screen());
    }
  }

  // ── Route builders ────────────────────────────────────────────────────────

  static MaterialPageRoute<dynamic> _buildRoute(
    RouteSettings settings,
    Widget screen, {
    bool requireAuth = false,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      builder: (context) {
        if (requireAuth) {
          return _buildAuthenticatedRoute(context, screen, settings.name!);
        }
        return screen;
      },
    );
  }

  static Widget _buildAuthenticatedRoute(
    BuildContext context,
    Widget screen,
    String route,
  ) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userRole = authProvider.user?.role;

        return RouteGuardWidget(
          route: route,
          isAuthenticated: isAuthenticated,
          userRole: userRole,
          onUnauthorized: () {
            if (!isAuthenticated) {
              Future.microtask(() {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              });
            }
          },
          child: screen,
        );
      },
    );
  }

  static Route<T> _buildFadeRoute<T>(RouteSettings settings, Widget screen) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> _buildSlideRoute<T>(
    RouteSettings settings,
    Widget screen, {
    AxisDirection direction = AxisDirection.right,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) {
        final Offset begin;
        switch (direction) {
          case AxisDirection.up:
            begin = const Offset(0, 1);
            break;
          case AxisDirection.down:
            begin = const Offset(0, -1);
            break;
          case AxisDirection.left:
            begin = const Offset(-1, 0);
            break;
          case AxisDirection.right:
            begin = const Offset(1, 0);
            break;
        }
        final tween = Tween(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ── Screen factories ──────────────────────────────────────────────────────

  static Widget _getLoginScreen() => const LoginScreen();

  static Widget _getSignupScreen() => const CustomerSignupScreen();

  static Widget _getForgotPasswordScreen() => const Placeholder();

  static Widget _getHomeScreen(String route) {
    switch (route) {
      case AppRoutes.customerHome:
        return const CustomerHomeScreen();
      case AppRoutes.branchManagerHome:
        return const HomeScreen();
      case AppRoutes.loanOfficerHome:
        return const HomeScreen();
      case AppRoutes.cardOfficerHome:
        return const HomeScreen();
      case AppRoutes.adminHome:
        return const HomeScreen();
      case AppRoutes.superAdminHome:
        return const HomeScreen();
      case AppRoutes.employeeHome:
        return const HomeScreen();
      default:
        return const HomeScreen();
    }
  }

  static Widget _getAccountsScreen() => const AccountListScreen();

  static Widget _getAccountDetailsScreen(dynamic args) =>
      const AccountDetailsScreen(accountNumber: '');

  static Widget _getBranchListScreen() => const BranchListScreen();

  static Widget _getProfileScreen() => const Placeholder();

  static Widget _getSettingsScreen() => const Placeholder();

  static Widget _getNotificationsScreen() => const Placeholder();

  static Widget _get404Screen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}

extension NavigationExtension on BuildContext {
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.pushNamed<T>(this, routeName, arguments: arguments);

  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) => Navigator.pushNamedAndRemoveUntil<T>(
    this,
    routeName,
    predicate,
    arguments: arguments,
  );

  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) => Navigator.pushReplacementNamed<T, TO>(
    this,
    routeName,
    arguments: arguments,
    result: result,
  );

  void pop<T>([T? result]) => Navigator.pop<T>(this, result);

  bool canPop() => Navigator.canPop(this);

  void popUntil(bool Function(Route<dynamic>) predicate) =>
      Navigator.popUntil(this, predicate);
}
