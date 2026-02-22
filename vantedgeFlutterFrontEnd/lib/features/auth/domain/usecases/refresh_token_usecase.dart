import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/auth_exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository _repository;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  RefreshTokenUseCase({
    required AuthRepository repository,
    required SecureStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  Future<void> call() async {
    try {
      _logger.i('Executing refresh token use case');

      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.e('No refresh token available');
        throw const TokenExpiredException(
          message: 'No refresh token available',
          tokenType: 'refresh',
        );
      }

      final authResponse = await _repository.refreshToken(refreshToken);

      await _updateStoredTokens(authResponse.toJson());

      _logger.i('Token refresh use case completed successfully');
    } catch (e) {
      _logger.e('Token refresh use case failed: $e');
      
      if (e is TokenExpiredException) {
        await _handleExpiredToken();
      }
      
      rethrow;
    }
  }

  Future<void> _updateStoredTokens(Map<String, dynamic> authData) async {
    try {
      await _storageService.saveAccessToken(authData['accessToken']);
      await _storageService.saveRefreshToken(authData['refreshToken']);
      
      final now = DateTime.now();
      final expiryTime = now.add(const Duration(hours: 24));
      await _storageService.saveTokenExpiry(expiryTime.millisecondsSinceEpoch);
      
      _logger.d('Tokens updated in storage');
    } catch (e) {
      _logger.e('Failed to update stored tokens: $e');
      rethrow;
    }
  }

  Future<void> _handleExpiredToken() async {
    try {
      _logger.w('Refresh token expired, clearing auth data');
      await _storageService.clearAuthData();
    } catch (e) {
      _logger.e('Error clearing auth data: $e');
    }
  }
}