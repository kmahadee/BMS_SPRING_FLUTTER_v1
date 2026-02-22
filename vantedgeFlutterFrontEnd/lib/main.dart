import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/features/auth/domain/usecases/CheckAuthStatusUseCase.dart';
import 'package:vantedge/features/auth/domain/usecases/ValidateTokenUseCase.dart';
import 'package:vantedge/features/customer/domain/repositories/customer_repository_impl.dart';
import 'package:vantedge/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:vantedge/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';

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
  print('🚀 [MAIN] Ensuring widgets binding initialized');
  
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ [MAIN] Widgets binding initialized');

  print('🚀 [MAIN] Initializing ErrorHandler');
  ErrorHandler().initialize();
  print('✅ [MAIN] ErrorHandler initialized');

  print('🚀 [MAIN] Setting system UI overlay style');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  print('✅ [MAIN] System UI overlay style set');

  print('🚀 [MAIN] Setting preferred orientations');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  print('✅ [MAIN] Preferred orientations set');

  print('🚀 [MAIN] Calling runApp');
  runApp(const MyApp());
  print('✅ [MAIN] runApp called');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final List<ChangeNotifierProvider> _providers;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  // Debug tracking
  int _buildCount = 0;
  DateTime? _initTime;

  @override
  void initState() {
    super.initState();
    _initTime = DateTime.now();
    print('🏗️ [MyApp] initState started at ${_initTime!.toIso8601String()}');
    
    print('🏗️ [MyApp] Building providers');
    _providers = _buildProviders();
    print('✅ [MyApp] Built ${_providers.length} providers');

    print('🏗️ [MyApp] Scheduling post-frame callback for splash navigation');
    // Navigate to SplashScreen AFTER the first frame is fully rendered.
    // By this point MultiProvider + MaterialApp + Navigator are all mounted,
    // so the route's BuildContext will correctly find all providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final elapsed = DateTime.now().difference(_initTime!).inMilliseconds;
      print('⏱️ [MyApp] Post-frame callback executing (${elapsed}ms after initState)');
      print('⏱️ [MyApp] Current _navigatorKey state: ${_navigatorKey.currentState != null ? 'available' : 'NULL!'}');
      
      if (_navigatorKey.currentState != null) {
        print('⏱️ [MyApp] Pushing splash screen route: ${AppRoutes.splash}');
        _navigatorKey.currentState?.pushReplacementNamed(AppRoutes.splash);
        print('✅ [MyApp] Splash navigation called');
      } else {
        print('❌ [MyApp] CRITICAL: _navigatorKey.currentState is null! Cannot navigate to splash.');
      }
    });
    
    print('🏗️ [MyApp] initState completed');
  }

  List<ChangeNotifierProvider> _buildProviders() {
    print('🏗️ [MyApp] _buildProviders started');
    
    print('  📦 Initializing DioClient');
    final dioClient = DioClient();
    dioClient.initialize();
    print('  ✅ DioClient initialized with baseUrl: ${dioClient.dio?.options.baseUrl}');

    print('  📦 Initializing SecureStorageService');
    final secureStorage = SecureStorageService();
    print('  ✅ SecureStorageService initialized');

    print('  📦 Building AuthRepository');
    final authRepository = AuthRepositoryImpl(
      dioClient: dioClient,
      storageService: secureStorage,
    );
    print('  ✅ AuthRepository built');

    print('  📦 Building CustomerRepository');
    final customerRepository = CustomerRepositoryImpl(dioClient: dioClient);
    print('  ✅ CustomerRepository built');

    print('  📦 Building BranchRepository');
    final branchRepository = BranchRepositoryImpl(dioClient: dioClient);
    print('  ✅ BranchRepository built');

    print('  📦 Building AccountRepository');
    final accountRepository = AccountRepositoryImpl(dioClient: dioClient);
    print('  ✅ AccountRepository built');

    print('  📦 Building TransactionRepository');
    final transactionRepository = TransactionRepositoryImpl(dioClient: dioClient);
    print('  ✅ TransactionRepository built');

    print('  📦 Building Use Cases');
    final loginUseCase = LoginUseCase(
      repository: authRepository,
      storageService: secureStorage,
    );
    final registerUseCase = RegisterUseCase(repository: authRepository);
    final registerUserUseCase = RegisterUserUseCase(repository: authRepository);
    final createCustomerUseCase = CreateCustomerUseCase(repository: customerRepository);
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
    final checkAuthStatusUseCase = CheckAuthStatusUseCase(
      repository: authRepository,
    );
    print('  ✅ All use cases built');

    print('  📦 Creating provider list');
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
    ];
    print('  ✅ Provider list created with ${providers.length} providers');

    print('🏗️ [MyApp] _buildProviders completed');
    return providers;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🏗️ [MyApp] didChangeDependencies called (build #$_buildCount)');
  }

  @override
  void dispose() {
    print('🏗️ [MyApp] dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final elapsed = _initTime != null 
        ? DateTime.now().difference(_initTime!).inMilliseconds 
        : 0;
    
    print('\n🏗️ [MyApp] 🔨 BUILD METHOD CALLED 🔨');
    print('  - Build count: $_buildCount');
    print('  - Time since init: ${elapsed}ms');
    print('  - Widget mounted: $mounted');
    print('  - Providers count: ${_providers.length}');
    print('  - Navigator key current state: ${_navigatorKey.currentState != null ? 'available' : 'null'}');

    return MultiProvider(
      providers: _providers,
      child: MaterialApp(
        title: 'Bank Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        navigatorKey: _navigatorKey,
        // No initialRoute — navigation happens via postFrameCallback above.
        // The '/' route just shows a blank screen for the one frame before
        // the navigator pushes SplashScreen with a fully mounted context.
        routes: {
          '/': (_) {
            print('   📍 [Route] / route builder called');
            return const SizedBox.shrink();
          },
        },
        onGenerateRoute: (settings) {
          print('   📍 [Route] onGenerateRoute called for: ${settings.name}');
          return AppRouter.generateRoute(settings);
        },
        builder: (context, child) {
          print('   🏗️ [MyApp] MaterialApp builder called');
          ErrorWidget.builder = (FlutterErrorDetails details) {
            print('   ❌ [MyApp] ErrorWidget builder called: ${details.exception}');
            return _buildErrorWidget(details);
          };
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    print('   ❌ [MyApp] Building error widget for: ${details.exception}');
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'re sorry for the inconvenience.\nPlease restart the app.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
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
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
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