import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/core/exceptions/auth_exceptions.dart';
import 'package:vantedge/features/auth/data/dto/user_registration_dto.dart';
import 'package:vantedge/features/auth/domain/usecases/CheckAuthStatusUseCase.dart';
import 'package:vantedge/features/auth/domain/usecases/ValidateTokenUseCase.dart';
import 'package:vantedge/features/auth/domain/usecases/register_user_usecase.dart';
import 'package:vantedge/features/customer/domain/usecases/create_customer_usecase.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../data/dto/customer_registration_dto.dart';
import '../../data/dto/login_request_dto.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';

import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

import 'auth_state.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final RegisterUserUseCase _registerUserUseCase;
  final CreateCustomerUseCase _createCustomerUseCase;
  final LogoutUseCase _logoutUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final ValidateTokenUseCase _validateTokenUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  AuthState _state = AuthState.initial();

  AuthProvider({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required RegisterUserUseCase registerUserUseCase,
    required CreateCustomerUseCase createCustomerUseCase,
    required LogoutUseCase logoutUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required ValidateTokenUseCase validateTokenUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required SecureStorageService storageService,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _registerUserUseCase = registerUserUseCase, 
        _createCustomerUseCase = createCustomerUseCase,
        _logoutUseCase = logoutUseCase,
        _refreshTokenUseCase = refreshTokenUseCase,
        _validateTokenUseCase = validateTokenUseCase,
        _checkAuthStatusUseCase = checkAuthStatusUseCase,
        _storageService = storageService {
    _initialize();
  }

  // Getters
  AuthState get state => _state;
  UserEntity? get user => _state.user;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  AuthStatus get status => _state.status;

  // Initialization
  void _initialize() {
    _logger.i('Initializing AuthProvider');
    checkAuthStatus();
  }

  // Check authentication status
  Future<void> checkAuthStatus() async {
    try {
      _logger.d('Checking authentication status');

      final isAuth = await _checkAuthStatusUseCase.call();

      if (isAuth) {
        final isTokenValid = await _validateTokenUseCase.call();

        if (isTokenValid) {
          await _loadUserFromStorage();
        } else {
          _updateState(AuthState.unauthenticated());
        }
      } else {
        _updateState(AuthState.unauthenticated());
      }
    } catch (e) {
      _logger.e('Error checking auth status: $e');
      _updateState(AuthState.unauthenticated());
    }
  }

  // Load user from storage
  Future<void> _loadUserFromStorage() async {
    try {
      final userId = await _storageService.getUserId();
      final username = await _storageService.getUsername();
      final roleString = await _storageService.getUserRole();
      final userData = await _storageService.getUserData();

      if (userId != null && username != null && roleString != null) {
        final user = UserEntity(
          id: userId,
          username: username,
          email: userData?['email'] ?? '',
          role: UserRole.fromString(roleString),
          fullName: username,
          customerId: userData?['customerId'],
        );

        _updateState(AuthState.authenticated(user));
        _logger.i('User loaded from storage: ${user.username}');
      } else {
        _logger.w('Incomplete user data in storage');
        _updateState(AuthState.unauthenticated());
      }
    } catch (e) {
      _logger.e('Error loading user from storage: $e');
      _updateState(AuthState.unauthenticated());
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    try {
      _logger.i('Login attempt for: $username');
      _updateState(AuthState.loading());

      final request = LoginRequestDTO(
        username: username,
        password: password,
      );

      final user = await _loginUseCase.call(request);

      _updateState(AuthState.authenticated(user));
      _logger.i('Login successful for: $username');

      return true;
    } on InvalidCredentialsException catch (e) {
      _logger.w('Invalid credentials: ${e.message}');
      _updateState(AuthState.error(e.getUserMessage()));
      return false;
    } on AccountNotApprovedException catch (e) {
      _logger.w('Account not approved: ${e.message}');
      _updateState(AuthState.error(e.getUserMessage()));
      return false;
    } on AccountLockedException catch (e) {
      _logger.w('Account locked: ${e.message}');
      _updateState(AuthState.error(e.getUserMessage()));
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } catch (e) {
      _logger.e('Login failed: $e');
      _updateState(AuthState.error('Login failed. Please try again.'));
      return false;
    }
  }

  // Register employee (branch manager, loan officer, etc.) - uses /auth/register
  Future<bool> register(CustomerRegistrationDTO data) async {
    try {
      _logger.i('Employee registration attempt for: ${data.email}');
      _updateState(AuthState.loading());

      await _registerUseCase.call(data);

      _updateState(AuthState.unauthenticated(
        'Employee registration successful! Please wait for admin approval.',
      ));
      _logger.i('Employee registration successful for: ${data.email}');

      return true;
    } on BadRequestException catch (e) {
      _logger.w('Registration validation failed: ${e.message}');
      final errorMsg = e.validationErrors?.values.join('\n') ?? e.message;
      _updateState(AuthState.error(errorMsg));
      return false;
    } on ConflictException catch (e) {
      _logger.w('Registration conflict: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } catch (e) {
      _logger.e('Employee registration failed: $e');
      _updateState(AuthState.error('Registration failed. Please try again.'));
      return false;
    }
  }

  Future<bool> registerEmployee(UserRegistrationDTO data) async {
    try {
      _logger.i('Employee registration attempt for: ${data.email}');
      _updateState(AuthState.loading());

      await _registerUserUseCase.call(data);

      _updateState(AuthState.unauthenticated(
        'Employee registration submitted! Please wait for admin approval.',
      ));
      _logger.i('Employee registration successful for: ${data.email}');

      return true;
    } on BadRequestException catch (e) {
      _logger.w('Employee registration validation failed: ${e.message}');
      final errorMsg = e.validationErrors?.values.join('\n') ?? e.message;
      _updateState(AuthState.error(errorMsg));
      return false;
    } on ConflictException catch (e) {
      _logger.w('Employee registration conflict: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } catch (e) {
      _logger.e('Employee registration failed: $e');
      _updateState(AuthState.error('Registration failed. Please try again.'));
      return false;
    }
  }


  // Register customer - uses /api/customers
  Future<bool> registerCustomer(CustomerRegistrationDTO data) async {
    try {
      _logger.i('Customer registration attempt for: ${data.email}');
      _updateState(AuthState.loading());

      await _createCustomerUseCase.call(data);

      _updateState(AuthState.unauthenticated(
        'Registration successful! Please login to continue.',
      ));
      _logger.i('Customer registration successful for: ${data.email}');

      return true;
    } on BadRequestException catch (e) {
      _logger.w('Customer registration validation failed: ${e.message}');
      final errorMsg = e.validationErrors?.values.join('\n') ?? e.message;
      _updateState(AuthState.error(errorMsg));
      return false;
    } on ConflictException catch (e) {
      _logger.w('Customer registration conflict: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _updateState(AuthState.error(e.message));
      return false;
    } catch (e) {
      _logger.e('Customer registration failed: $e');
      _updateState(AuthState.error('Registration failed. Please try again.'));
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _logger.i('Logout initiated');
      _updateState(AuthState.loading());

      await _logoutUseCase.call();

      _updateState(AuthState.unauthenticated('Logged out successfully'));
      _logger.i('Logout successful');
    } catch (e) {
      _logger.e('Logout failed: $e');
      _updateState(AuthState.unauthenticated('Logged out'));
    }
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      _logger.d('Refreshing token');

      await _refreshTokenUseCase.call();

      await _loadUserFromStorage();

      _logger.i('Token refresh successful');
    } on TokenExpiredException catch (e) {
      _logger.e('Token expired: ${e.message}');
      _updateState(AuthState.unauthenticated('Session expired. Please login again.'));
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      _updateState(AuthState.unauthenticated('Session expired. Please login again.'));
    }
  }

  // Clear error
  void clearError() {
    if (_state.hasError) {
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      ));
      _logger.d('Error cleared');
    }
  }

  // Update state and notify listeners
  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
    _logger.d('State updated: ${_state.status}');
  }

  @override
  void dispose() {
    _logger.d('AuthProvider disposed');
    super.dispose();
  }
}



// import 'package:flutter/foundation.dart';
// import 'package:logger/logger.dart';
// import 'package:vantedge/core/exceptions/api_exceptions.dart';
// import 'package:vantedge/core/exceptions/auth_exceptions.dart';
// import 'package:vantedge/features/auth/domain/usecases/CheckAuthStatusUseCase.dart';
// import 'package:vantedge/features/auth/domain/usecases/ValidateTokenUseCase.dart';

// import '../../../../core/storage/secure_storage_service.dart';
// import '../../data/dto/customer_registration_dto.dart';
// import '../../data/dto/login_request_dto.dart';
// import '../../domain/entities/user_entity.dart';
// import '../../domain/entities/user_role.dart';

// import '../../domain/usecases/login_usecase.dart';
// import '../../domain/usecases/logout_usecase.dart';
// import '../../domain/usecases/refresh_token_usecase.dart';
// import '../../domain/usecases/register_usecase.dart';

// import 'auth_state.dart';

// class AuthProvider extends ChangeNotifier {
//   final LoginUseCase _loginUseCase;
//   final RegisterUseCase _registerUseCase;
//   final LogoutUseCase _logoutUseCase;
//   final RefreshTokenUseCase _refreshTokenUseCase;
//   final ValidateTokenUseCase _validateTokenUseCase;
//   final CheckAuthStatusUseCase _checkAuthStatusUseCase;
//   final SecureStorageService _storageService;
//   final Logger _logger = Logger();

//   AuthState _state = AuthState.initial();

//   AuthProvider({
//     required LoginUseCase loginUseCase,
//     required RegisterUseCase registerUseCase,
//     required LogoutUseCase logoutUseCase,
//     required RefreshTokenUseCase refreshTokenUseCase,
//     required ValidateTokenUseCase validateTokenUseCase,
//     required CheckAuthStatusUseCase checkAuthStatusUseCase,
//     required SecureStorageService storageService,
//   })  : _loginUseCase = loginUseCase,
//         _registerUseCase = registerUseCase,
//         _logoutUseCase = logoutUseCase,
//         _refreshTokenUseCase = refreshTokenUseCase,
//         _validateTokenUseCase = validateTokenUseCase,
//         _checkAuthStatusUseCase = checkAuthStatusUseCase,
//         _storageService = storageService {
//     _initialize();
//   }

//   AuthState get state => _state;
//   UserEntity? get user => _state.user;
//   bool get isAuthenticated => _state.isAuthenticated;
//   bool get isLoading => _state.isLoading;
//   String? get errorMessage => _state.errorMessage;
//   AuthStatus get status => _state.status;

//   void _initialize() {
//     _logger.i('Initializing AuthProvider');
//     checkAuthStatus();
//   }

//   Future<void> checkAuthStatus() async {
//     try {
//       _logger.d('Checking authentication status');

//       final isAuth = await _checkAuthStatusUseCase.call();

//       if (isAuth) {
//         final isTokenValid = await _validateTokenUseCase.call();

//         if (isTokenValid) {
//           await _loadUserFromStorage();
//         } else {
//           _updateState(AuthState.unauthenticated());
//         }
//       } else {
//         _updateState(AuthState.unauthenticated());
//       }
//     } catch (e) {
//       _logger.e('Error checking auth status: $e');
//       _updateState(AuthState.unauthenticated());
//     }
//   }

//   Future<void> _loadUserFromStorage() async {
//     try {
//       final userId = await _storageService.getUserId();
//       final username = await _storageService.getUsername();
//       final roleString = await _storageService.getUserRole();
//       final userData = await _storageService.getUserData();

//       if (userId != null && username != null && roleString != null) {
//         final user = UserEntity(
//           id: userId,
//           username: username,
//           email: userData?['email'] ?? '',
//           role: UserRole.fromString(roleString),
//           fullName: username,
//           customerId: userData?['customerId'],
//         );

//         _updateState(AuthState.authenticated(user));
//         _logger.i('User loaded from storage: ${user.username}');
//       } else {
//         _logger.w('Incomplete user data in storage');
//         _updateState(AuthState.unauthenticated());
//       }
//     } catch (e) {
//       _logger.e('Error loading user from storage: $e');
//       _updateState(AuthState.unauthenticated());
//     }
//   }

//   Future<bool> login(String username, String password) async {
//     try {
//       _logger.i('Login attempt for: $username');
//       _updateState(AuthState.loading());

//       final request = LoginRequestDTO(
//         username: username,
//         password: password,
//       );

//       final user = await _loginUseCase.call(request);

//       _updateState(AuthState.authenticated(user));
//       _logger.i('Login successful for: $username');

//       return true;
//     } on InvalidCredentialsException catch (e) {
//       _logger.w('Invalid credentials: ${e.message}');
//       _updateState(AuthState.error(e.getUserMessage()));
//       return false;
//     } on AccountNotApprovedException catch (e) {
//       _logger.w('Account not approved: ${e.message}');
//       _updateState(AuthState.error(e.getUserMessage()));
//       return false;
//     } on AccountLockedException catch (e) {
//       _logger.w('Account locked: ${e.message}');
//       _updateState(AuthState.error(e.getUserMessage()));
//       return false;
//     } on UnauthorizedException catch (e) {
//       _logger.e('Unauthorized: ${e.message}');
//       _updateState(AuthState.error(e.message));
//       return false;
//     } on NetworkException catch (e) {
//       _logger.e('Network error: ${e.message}');
//       _updateState(AuthState.error(e.message));
//       return false;
//     } catch (e) {
//       _logger.e('Login failed: $e');
//       _updateState(AuthState.error('Login failed. Please try again.'));
//       return false;
//     }
//   }

//   Future<bool> register(CustomerRegistrationDTO data) async {
//     try {
//       _logger.i('Registration attempt for: ${data.email}');
//       _updateState(AuthState.loading());

//       await _registerUseCase.call(data);

//       _updateState(AuthState.unauthenticated(
//         'Registration successful! Please login.',
//       ));
//       _logger.i('Registration successful for: ${data.email}');

//       return true;
//     } on BadRequestException catch (e) {
//       _logger.w('Registration validation failed: ${e.message}');
//       final errorMsg = e.validationErrors?.values.join('\n') ?? e.message;
//       _updateState(AuthState.error(errorMsg));
//       return false;
//     } on ConflictException catch (e) {
//       _logger.w('Registration conflict: ${e.message}');
//       _updateState(AuthState.error(e.message));
//       return false;
//     } on NetworkException catch (e) {
//       _logger.e('Network error: ${e.message}');
//       _updateState(AuthState.error(e.message));
//       return false;
//     } catch (e) {
//       _logger.e('Registration failed: $e');
//       _updateState(AuthState.error('Registration failed. Please try again.'));
//       return false;
//     }
//   }

//   Future<void> logout() async {
//     try {
//       _logger.i('Logout initiated');
//       _updateState(AuthState.loading());

//       await _logoutUseCase.call();

//       _updateState(AuthState.unauthenticated('Logged out successfully'));
//       _logger.i('Logout successful');
//     } catch (e) {
//       _logger.e('Logout failed: $e');
//       _updateState(AuthState.unauthenticated('Logged out'));
//     }
//   }

//   Future<void> refreshToken() async {
//     try {
//       _logger.d('Refreshing token');

//       await _refreshTokenUseCase.call();

//       await _loadUserFromStorage();

//       _logger.i('Token refresh successful');
//     } on TokenExpiredException catch (e) {
//       _logger.e('Token expired: ${e.message}');
//       _updateState(AuthState.unauthenticated('Session expired. Please login again.'));
//     } catch (e) {
//       _logger.e('Token refresh failed: $e');
//       _updateState(AuthState.unauthenticated('Session expired. Please login again.'));
//     }
//   }

//   void clearError() {
//     if (_state.hasError) {
//       _updateState(_state.copyWith(
//         status: AuthStatus.unauthenticated,
//         clearError: true,
//       ));
//       _logger.d('Error cleared');
//     }
//   }

//   void _updateState(AuthState newState) {
//     _state = newState;
//     notifyListeners();
//     _logger.d('State updated: ${_state.status}');
//   }

//   @override
//   void dispose() {
//     _logger.d('AuthProvider disposed');
//     super.dispose();
//   }
// }