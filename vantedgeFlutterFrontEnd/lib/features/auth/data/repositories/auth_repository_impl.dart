import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/features/auth/data/dto/user_registration_dto.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dto/auth_response_dto.dart';
import '../dto/customer_registration_dto.dart';
import '../dto/customer_response_dto.dart';
import '../dto/login_request_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  AuthRepositoryImpl({
    required DioClient dioClient,
    required SecureStorageService storageService,
  }) : _dioClient = dioClient,
       _storageService = storageService;

  @override
  Future<AuthResponseDTO> login(LoginRequestDTO request) async {
    try {
      _logger.i('Attempting login for user: ${request.username}');

      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: request.toJson(),
      );

      // FIXED: Removed ['data'] access since _parseResponse already unwraps it
      final authData = AuthResponseDTO.fromJson(response);

      await _saveAuthData(authData);

      _logger.i('Login successful for user: ${authData.username}');
      return authData;
    } catch (e) {
      _logger.e('Login failed: $e');
      rethrow;
    }
  }

  @override
  Future<CustomerResponseDTO> register(CustomerRegistrationDTO request) async {
    try {
      _logger.i('Attempting registration for: ${request.email}');

      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: request.toJson(),
      );

      // FIXED: Removed ['data'] access since _parseResponse already unwraps it
      final customerData = CustomerResponseDTO.fromJson(response);

      _logger.i('Registration successful for: ${customerData.email}');
      return customerData;
    } catch (e) {
      _logger.e('Registration failed: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResponseDTO> refreshToken(String refreshToken) async {
    try {
      _logger.i('Attempting token refresh');

      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      // FIXED: Removed ['data'] access since _parseResponse already unwraps it
      final authData = AuthResponseDTO.fromJson(response);

      await _saveAuthData(authData);

      _logger.i('Token refresh successful');
      return authData;
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      await _storageService.clearAuthData();
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      _logger.i('Attempting logout');

      await _dioClient.post<Map<String, dynamic>>(ApiConstants.logout);

      _logger.i('Logout API call successful');
    } catch (e) {
      _logger.w('Logout API call failed (continuing with local cleanup): $e');
    } finally {
      await _storageService.clearAuthData();
      _logger.i('Local auth data cleared');
    }
  }

  @override
  Future<bool> validateToken() async {
    try {
      final token = await _storageService.getAccessToken();

      if (token == null || token.isEmpty) {
        _logger.d('No token found');
        return false;
      }

      final isExpired = await _storageService.isTokenExpired();
      if (isExpired) {
        _logger.d('Token is expired');
        return false;
      }

      try {
        await _dioClient.get<Map<String, dynamic>>(ApiConstants.validateToken);
        _logger.d('Token validation successful');
        return true;
      } catch (e) {
        _logger.w('Token validation failed: $e');
        return false;
      }
    } catch (e) {
      _logger.e('Token validation error: $e');
      return false;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final hasToken = await _storageService.hasValidToken();
      final isAuth = await _storageService.getIsAuthenticated();

      return hasToken && isAuth;
    } catch (e) {
      _logger.e('Error checking authentication status: $e');
      return false;
    }
  }

  @override
  Future<void> registerUser(UserRegistrationDTO request) async {
    try {
      _logger.i('Attempting user registration for: ${request.email}');

      await _dioClient.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: request.toJson(),
      );

      _logger.i('User registration successful for: ${request.email}');
    } catch (e) {
      _logger.e('User registration failed: $e');
      rethrow;
    }
  }

  Future<void> _saveAuthData(AuthResponseDTO authData) async {
    try {
      await _storageService.saveAccessToken(authData.accessToken);

      // Handle nullable refreshToken - backend doesn't provide it currently
      if (authData.refreshToken != null) {
        await _storageService.saveRefreshToken(authData.refreshToken!);
      }

      await _storageService.saveUserId(authData.userId);
      await _storageService.saveUsername(authData.username);
      await _storageService.saveUserRole(authData.role);
      await _storageService.saveIsAuthenticated(true);

      if (authData.customerId != null) {
        await _storageService.saveUserData({'customerId': authData.customerId});
      }

      final now = DateTime.now();
      final expiryTime = now.add(const Duration(hours: 24));
      await _storageService.saveTokenExpiry(expiryTime.millisecondsSinceEpoch);

      _logger.d('Auth data saved successfully');
    } catch (e) {
      _logger.e('Failed to save auth data: $e');
      rethrow;
    }
  }
}