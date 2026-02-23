import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/features/auth/domain/usecases/CheckAuthStatusUseCase.dart';
import 'package:vantedge/features/auth/domain/usecases/ValidateTokenUseCase.dart';
import 'package:vantedge/features/customer/domain/repositories/customer_repository_impl.dart';
import 'package:vantedge/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:vantedge/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';

// ── Loan feature ──────────────────────────────────────────────────────────────
import 'package:vantedge/features/loans/data/repositories/loan_repository_impl.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_provider.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_officer_provider.dart';
// ─────────────────────────────────────────────────────────────────────────────

import 'core/error/error_handler.dart';
import 'core/navigation/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/register_user_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/refresh_token_usecase.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';

import 'features/customer/domain/usecases/create_customer_usecase.dart';

import 'features/branches/presentation/providers/branch_provider.dart';
import 'features/branches/data/repositories/branch_repository_impl.dart';

import 'features/accounts/presentation/providers/account_provider.dart';
import 'features/accounts/data/repositories/account_repository_impl.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/api/interceptors/dio_client.dart';

void main() async {
  print('🚀 [MAIN] Application starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ [MAIN] Widgets binding initialized');

  ErrorHandler().initialize();
  print('✅ [MAIN] ErrorHandler initialized');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final List<ChangeNotifierProvider> _providers;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  int _buildCount = 0;
  DateTime? _initTime;

  @override
  void initState() {
    super.initState();
    _initTime = DateTime.now();
    print('🏗️ [MyApp] initState started');
    _providers = _buildProviders();
    print('✅ [MyApp] Built ${_providers.length} providers');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('⏱️ [MyApp] Post-frame callback — navigating to splash');
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState?.pushReplacementNamed(AppRoutes.splash);
      } else {
        print('❌ [MyApp] CRITICAL: _navigatorKey.currentState is null!');
      }
    });
  }

  List<ChangeNotifierProvider> _buildProviders() {
    print('🏗️ [MyApp] _buildProviders started');

    // ── Infrastructure ────────────────────────────────────────────────────
    print('  📦 Initializing DioClient');
    final dioClient = DioClient();
    dioClient.initialize();
    print('  ✅ DioClient ready: ${dioClient.dio?.options.baseUrl}');

    final secureStorage = SecureStorageService();
    print('  ✅ SecureStorageService ready');

    // ── Repositories ──────────────────────────────────────────────────────
    final authRepository = AuthRepositoryImpl(
      dioClient: dioClient,
      storageService: secureStorage,
    );
    final customerRepository = CustomerRepositoryImpl(dioClient: dioClient);
    final branchRepository = BranchRepositoryImpl(dioClient: dioClient);
    final accountRepository = AccountRepositoryImpl(dioClient: dioClient);
    final transactionRepository =
        TransactionRepositoryImpl(dioClient: dioClient);

    // ── Loan repository — single instance shared by both loan providers ───
    print('  📦 Building LoanRepository');
    final loanRepository = LoanRepositoryImpl(dioClient: dioClient);
    print('  ✅ LoanRepository ready');
    // ─────────────────────────────────────────────────────────────────────

    // ── Use-cases ─────────────────────────────────────────────────────────
    final loginUseCase = LoginUseCase(
      repository: authRepository,
      storageService: secureStorage,
    );
    final registerUseCase = RegisterUseCase(repository: authRepository);
    final registerUserUseCase =
        RegisterUserUseCase(repository: authRepository);
    final createCustomerUseCase =
        CreateCustomerUseCase(repository: customerRepository);
    final logoutUseCase = LogoutUseCase(
      repository: authRepository,
      storageService: secureStorage,
    );
    final refreshTokenUseCase = RefreshTokenUseCase(
      repository: authRepository,
      storageService: secureStorage,
    );
    final validateTokenUseCase = ValidateTokenUseCase(
      repository: authRepository,
      storageService: secureStorage,
    );
    final checkAuthStatusUseCase =
        CheckAuthStatusUseCase(repository: authRepository);
    print('  ✅ All use cases ready');

    // ── Provider list ─────────────────────────────────────────────────────
    final providers = [
      ChangeNotifierProvider(
        create: (_) {
          print('    🔧 Creating AuthProvider');
          return AuthProvider(
            loginUseCase: loginUseCase,
            registerUseCase: registerUseCase,
            registerUserUseCase: registerUserUseCase,
            createCustomerUseCase: createCustomerUseCase,
            logoutUseCase: logoutUseCase,
            refreshTokenUseCase: refreshTokenUseCase,
            validateTokenUseCase: validateTokenUseCase,
            checkAuthStatusUseCase: checkAuthStatusUseCase,
            storageService: secureStorage,
          );
        },
      ),
      ChangeNotifierProvider(
        create: (_) {
          print('    🔧 Creating BranchProvider');
          return BranchProvider(repository: branchRepository);
        },
      ),
      ChangeNotifierProvider(
        create: (_) {
          print('    🔧 Creating AccountProvider');
          return AccountProvider(repository: accountRepository);
        },
      ),
      ChangeNotifierProvider(
        create: (_) {
          print('    🔧 Creating TransactionProvider');
          return TransactionProvider(repository: transactionRepository);
        },
      ),
      ChangeNotifierProvider(
        create: (_) {
          print('    🔧 Creating BadgeCountProvider');
          return BadgeCountProvider(dioClient: dioClient);
        },
      ),
      // ── Loan providers ─────────────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) {
          print('    🔧 Creating LoanProvider');
          return LoanProvider(repository: loanRepository);
        },
      ),
      ChangeNotifierProvider(
        create: (_) {
          print('    🔧 Creating LoanOfficerProvider');
          return LoanOfficerProvider(repository: loanRepository);
        },
      ),
      // ───────────────────────────────────────────────────────────────────
    ];

    print(
        '  ✅ Provider list created with ${providers.length} providers');
    print('🏗️ [MyApp] _buildProviders completed');
    return providers;
  }

  @override
  void dispose() {
    print('🏗️ [MyApp] dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final elapsed = _initTime != null
        ? DateTime.now().difference(_initTime!).inMilliseconds
        : 0;
    print('\n🏗️ [MyApp] BUILD #$_buildCount (${elapsed}ms since init)');

    return MultiProvider(
      providers: _providers,
      child: MaterialApp(
        title: 'Bank Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        navigatorKey: _navigatorKey,
        routes: {
          '/': (_) => const SizedBox.shrink(),
        },
        onGenerateRoute: (settings) {
          print('📍 [Route] ${settings.name}');
          return AppRouter.generateRoute(settings);
        },
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) =>
              _buildErrorWidget(details);
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.red.shade700),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'re sorry for the inconvenience.\nPlease restart the app.',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (details.stack != null)
                  ExpansionTile(
                    title: const Text('Error Details'),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey.shade100,
                        child: Text(
                          details.exception.toString(),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
