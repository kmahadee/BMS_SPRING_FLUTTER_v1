import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/constants/storage_keys.dart';

import 'storage_service_interface.dart';

class SecureStorageService implements IStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService() => _instance;
  
  SecureStorageService._internal();

  final _logger = Logger();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  @override
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: token);
      _logger.d('Access token saved');
    } catch (e) {
      _logger.e('Failed to save access token: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: StorageKeys.accessToken);
    } catch (e) {
      _logger.e('Failed to get access token: $e');
      return null;
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.refreshToken, value: token);
      _logger.d('Refresh token saved');
    } catch (e) {
      _logger.e('Failed to save refresh token: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: StorageKeys.refreshToken);
    } catch (e) {
      _logger.e('Failed to get refresh token: $e');
      return null;
    }
  }

  @override
  Future<void> saveTokenExpiry(int timestamp) async {
    try {
      await _storage.write(
        key: StorageKeys.tokenExpiry,
        value: timestamp.toString(),
      );
      _logger.d('Token expiry saved');
    } catch (e) {
      _logger.e('Failed to save token expiry: $e');
      rethrow;
    }
  }

  @override
  Future<int?> getTokenExpiry() async {
    try {
      final value = await _storage.read(key: StorageKeys.tokenExpiry);
      return value != null ? int.tryParse(value) : null;
    } catch (e) {
      _logger.e('Failed to get token expiry: $e');
      return null;
    }
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(
        key: StorageKeys.userData,
        value: jsonEncode(userData),
      );
      _logger.d('User data saved');
    } catch (e) {
      _logger.e('Failed to save user data: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: StorageKeys.userData);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to get user data: $e');
      return null;
    }
  }

  @override
  Future<void> saveUserRole(String role) async {
    try {
      await _storage.write(key: StorageKeys.userRole, value: role);
      _logger.d('User role saved: $role');
    } catch (e) {
      _logger.e('Failed to save user role: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: StorageKeys.userRole);
    } catch (e) {
      _logger.e('Failed to get user role: $e');
      return null;
    }
  }

  @override
  Future<void> saveUserId(int id) async {
    try {
      await _storage.write(key: StorageKeys.userId, value: id.toString());
      _logger.d('User ID saved: $id');
    } catch (e) {
      _logger.e('Failed to save user ID: $e');
      rethrow;
    }
  }

  @override
  Future<int?> getUserId() async {
    try {
      final idString = await _storage.read(key: StorageKeys.userId);
      return idString != null ? int.tryParse(idString) : null;
    } catch (e) {
      _logger.e('Failed to get user ID: $e');
      return null;
    }
  }

  @override
  Future<void> saveUsername(String username) async {
    try {
      await _storage.write(key: StorageKeys.username, value: username);
      _logger.d('Username saved');
    } catch (e) {
      _logger.e('Failed to save username: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: StorageKeys.username);
    } catch (e) {
      _logger.e('Failed to get username: $e');
      return null;
    }
  }

  @override
  Future<void> savePinCode(String hashedPin) async {
    try {
      await _storage.write(key: StorageKeys.pinCode, value: hashedPin);
      _logger.d('PIN code saved');
    } catch (e) {
      _logger.e('Failed to save PIN code: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getPinCode() async {
    try {
      return await _storage.read(key: StorageKeys.pinCode);
    } catch (e) {
      _logger.e('Failed to get PIN code: $e');
      return null;
    }
  }

  @override
  Future<void> saveIsAuthenticated(bool isAuthenticated) async {
    try {
      await _storage.write(
        key: StorageKeys.isAuthenticated,
        value: isAuthenticated.toString(),
      );
      _logger.d('Authentication status saved: $isAuthenticated');
    } catch (e) {
      _logger.e('Failed to save authentication status: $e');
      rethrow;
    }
  }

  @override
  Future<bool> getIsAuthenticated() async {
    try {
      final value = await _storage.read(key: StorageKeys.isAuthenticated);
      return value == 'true';
    } catch (e) {
      _logger.e('Failed to get authentication status: $e');
      return false;
    }
  }

  @override
  Future<void> saveRememberMe(bool rememberMe) async {
    try {
      await _storage.write(
        key: StorageKeys.rememberMe,
        value: rememberMe.toString(),
      );
      _logger.d('Remember me saved: $rememberMe');
    } catch (e) {
      _logger.e('Failed to save remember me: $e');
      rethrow;
    }
  }

  @override
  Future<bool> getRememberMe() async {
    try {
      final value = await _storage.read(key: StorageKeys.rememberMe);
      return value == 'true';
    } catch (e) {
      _logger.e('Failed to get remember me: $e');
      return false;
    }
  }

  @override
  Future<void> saveSavedUsername(String username) async {
    try {
      await _storage.write(key: StorageKeys.savedUsername, value: username);
      _logger.d('Saved username stored');
    } catch (e) {
      _logger.e('Failed to save username: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getSavedUsername() async {
    try {
      return await _storage.read(key: StorageKeys.savedUsername);
    } catch (e) {
      _logger.e('Failed to get saved username: $e');
      return null;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      _logger.i('All storage cleared');
    } catch (e) {
      _logger.e('Failed to clear all storage: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      final keysToDelete = StorageKeys.getLogoutClearKeys();
      for (final key in keysToDelete) {
        await _storage.delete(key: key);
      }
      _logger.i('Auth data cleared');
    } catch (e) {
      _logger.e('Failed to clear auth data: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearUserData() async {
    try {
      final keysToDelete = StorageKeys.getUserDataKeys();
      for (final key in keysToDelete) {
        await _storage.delete(key: key);
      }
      _logger.i('User data cleared');
    } catch (e) {
      _logger.e('Failed to clear user data: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasValidToken() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      _logger.e('Failed to validate token: $e');
      return false;
    }
  }

  @override
  Future<bool> isTokenExpired() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return true;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      return now >= expiry;
    } catch (e) {
      _logger.e('Failed to check token expiry: $e');
      return true;
    }
  }
}