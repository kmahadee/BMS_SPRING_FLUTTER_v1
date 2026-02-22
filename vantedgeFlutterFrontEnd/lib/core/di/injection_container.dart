import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/features/auth/domain/usecases/CheckAuthStatusUseCase.dart';
import 'package:vantedge/features/auth/domain/usecases/ValidateTokenUseCase.dart';
import 'package:vantedge/features/auth/domain/usecases/register_user_usecase.dart';
import 'package:vantedge/features/customer/domain/repositories/customer_repository_impl.dart';
import 'package:vantedge/features/customer/domain/usecases/create_customer_usecase.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

// Customer imports
import '../../features/customer/domain/repositories/customer_repository.dart';



import '../storage/secure_storage_service.dart';
import '../storage/storage_service_interface.dart';
import 'service_locator.dart';

Future<void> init() async {
  try {
    final logger = Logger();
    logger.i('Initializing dependency injection container');

    await _initCore();
    await _initStorage();
    await _initNetwork();
    await _initRepositories();
    await _initUseCases();
    await _initProviders();

    logger.i('Dependency injection container initialized successfully');
  } catch (e) {
    final logger = Logger();
    logger.e('Failed to initialize dependency injection: $e');
    rethrow;
  }
}

Future<void> _initCore() async {
  sl.registerLazySingleton<Logger>(() => Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 50,
          colors: true,
          printEmojis: true,
        ),
      ));

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
}

Future<void> _initStorage() async {
  const androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    ),
  );

  sl.registerLazySingleton<IStorageService>(
    () => SecureStorageService(),
  );

  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
}

Future<void> _initNetwork() async {
  sl.registerLazySingleton<DioClient>(() {
    final client = DioClient();
    client.initialize();
    return client;
  });
}

Future<void> _initRepositories() async {
  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      dioClient: sl<DioClient>(),
      storageService: sl<SecureStorageService>(),
    ),
  );

  // Customer Repository
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      dioClient: sl<DioClient>(),
    ),
  );
}

Future<void> _initUseCases() async {
  // Auth Use Cases
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(
      repository: sl<AuthRepository>(),
      storageService: sl<SecureStorageService>(),
    ),
  );

  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(
      repository: sl<AuthRepository>(),
    ),
  );

  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(
      repository: sl<AuthRepository>(),
      storageService: sl<SecureStorageService>(),
    ),
  );

  sl.registerLazySingleton<RefreshTokenUseCase>(
    () => RefreshTokenUseCase(
      repository: sl<AuthRepository>(),
      storageService: sl<SecureStorageService>(),
    ),
  );

  sl.registerLazySingleton<ValidateTokenUseCase>(
    () => ValidateTokenUseCase(
      repository: sl<AuthRepository>(),
      storageService: sl<SecureStorageService>(),
    ),
  );

  sl.registerLazySingleton<CheckAuthStatusUseCase>(
    () => CheckAuthStatusUseCase(
      repository: sl<AuthRepository>(),
    ),
  );

  // Customer Use Cases
  sl.registerLazySingleton<CreateCustomerUseCase>(
    () => CreateCustomerUseCase(
      repository: sl<CustomerRepository>(),
    ),
  );


  //User Registration

  sl.registerLazySingleton<RegisterUserUseCase>(
  () => RegisterUserUseCase(
    repository: sl<AuthRepository>(),
  ),
);
}

Future<void> _initProviders() async {
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      registerUserUseCase: sl<RegisterUserUseCase>(),
      createCustomerUseCase: sl<CreateCustomerUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      refreshTokenUseCase: sl<RefreshTokenUseCase>(),
      validateTokenUseCase: sl<ValidateTokenUseCase>(),
      checkAuthStatusUseCase: sl<CheckAuthStatusUseCase>(),
      storageService: sl<SecureStorageService>(),
    ),
  );
}

Future<void> reset() async {
  await sl.reset();
  final logger = Logger();
  logger.i('Dependency injection container reset');
}



// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:logger/logger.dart';
// import 'package:vantedge/core/api/interceptors/dio_client.dart';
// import 'package:vantedge/features/auth/domain/usecases/CheckAuthStatusUseCase.dart';
// import 'package:vantedge/features/auth/domain/usecases/ValidateTokenUseCase.dart';
// import '../../features/auth/data/repositories/auth_repository_impl.dart';
// import '../../features/auth/domain/repositories/auth_repository.dart';

// import '../../features/auth/domain/usecases/login_usecase.dart';
// import '../../features/auth/domain/usecases/logout_usecase.dart';
// import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
// import '../../features/auth/domain/usecases/register_usecase.dart';

// import '../../features/auth/presentation/providers/auth_provider.dart';

// import '../storage/secure_storage_service.dart';
// import '../storage/storage_service_interface.dart';
// import 'service_locator.dart';

// Future<void> init() async {
//   try {
//     final logger = Logger();
//     logger.i('Initializing dependency injection container');

//     await _initCore();
//     await _initStorage();
//     await _initNetwork();
//     await _initRepositories();
//     await _initUseCases();
//     await _initProviders();

//     logger.i('Dependency injection container initialized successfully');
//   } catch (e) {
//     final logger = Logger();
//     logger.e('Failed to initialize dependency injection: $e');
//     rethrow;
//   }
// }

// Future<void> _initCore() async {
//   sl.registerLazySingleton<Logger>(() => Logger(
//         printer: PrettyPrinter(
//           methodCount: 0,
//           errorMethodCount: 5,
//           lineLength: 50,
//           colors: true,
//           printEmojis: true,
//         ),
//       ));

//   sl.registerLazySingleton<Connectivity>(() => Connectivity());
// }

// Future<void> _initStorage() async {
//   const androidOptions = AndroidOptions(
//     encryptedSharedPreferences: true,
//   );

//   const iosOptions = IOSOptions(
//     accessibility: KeychainAccessibility.first_unlock,
//   );

//   sl.registerLazySingleton<FlutterSecureStorage>(
//     () => const FlutterSecureStorage(
//       aOptions: androidOptions,
//       iOptions: iosOptions,
//     ),
//   );

//   sl.registerLazySingleton<IStorageService>(
//     () => SecureStorageService(),
//   );

//   sl.registerLazySingleton<SecureStorageService>(
//     () => SecureStorageService(),
//   );
// }

// Future<void> _initNetwork() async {
//   sl.registerLazySingleton<DioClient>(() {
//     final client = DioClient();
//     client.initialize();
//     return client;
//   });
// }

// Future<void> _initRepositories() async {
//   sl.registerLazySingleton<AuthRepository>(
//     () => AuthRepositoryImpl(
//       dioClient: sl<DioClient>(),
//       storageService: sl<SecureStorageService>(),
//     ),
//   );
// }

// Future<void> _initUseCases() async {
//   sl.registerLazySingleton<LoginUseCase>(
//     () => LoginUseCase(
//       repository: sl<AuthRepository>(),
//       storageService: sl<SecureStorageService>(),
//     ),
//   );

//   sl.registerLazySingleton<RegisterUseCase>(
//     () => RegisterUseCase(
//       repository: sl<AuthRepository>(),
//     ),
//   );

//   sl.registerLazySingleton<LogoutUseCase>(
//     () => LogoutUseCase(
//       repository: sl<AuthRepository>(),
//       storageService: sl<SecureStorageService>(),
//     ),
//   );

//   sl.registerLazySingleton<RefreshTokenUseCase>(
//     () => RefreshTokenUseCase(
//       repository: sl<AuthRepository>(),
//       storageService: sl<SecureStorageService>(),
//     ),
//   );

//   sl.registerLazySingleton<ValidateTokenUseCase>(
//     () => ValidateTokenUseCase(
//       repository: sl<AuthRepository>(),
//       storageService: sl<SecureStorageService>(),
//     ),
//   );

//   sl.registerLazySingleton<CheckAuthStatusUseCase>(
//     () => CheckAuthStatusUseCase(
//       repository: sl<AuthRepository>(),
//     ),
//   );
// }

// Future<void> _initProviders() async {
//   sl.registerLazySingleton<AuthProvider>(
//     () => AuthProvider(
//       loginUseCase: sl<LoginUseCase>(),
//       registerUseCase: sl<RegisterUseCase>(),
//       logoutUseCase: sl<LogoutUseCase>(),
//       refreshTokenUseCase: sl<RefreshTokenUseCase>(),
//       validateTokenUseCase: sl<ValidateTokenUseCase>(),
//       checkAuthStatusUseCase: sl<CheckAuthStatusUseCase>(),
//       storageService: sl<SecureStorageService>(),
//     ),
//   );
// }

// Future<void> reset() async {
//   await sl.reset();
//   final logger = Logger();
//   logger.i('Dependency injection container reset');
// }