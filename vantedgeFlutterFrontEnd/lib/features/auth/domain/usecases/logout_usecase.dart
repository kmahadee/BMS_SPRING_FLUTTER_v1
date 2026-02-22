import 'package:logger/logger.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repository;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  LogoutUseCase({
    required AuthRepository repository,
    required SecureStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  Future<void> call() async {
    try {
      _logger.i('Executing logout use case');

      await _repository.logout();

      await _clearLocalData();

      _logger.i('Logout use case completed successfully');
    } catch (e) {
      _logger.e('Logout use case failed: $e');

      try {
        await _clearLocalData();
        _logger.i('Local data cleared despite logout error');
      } catch (clearError) {
        _logger.e('Failed to clear local data: $clearError');
        rethrow;
      }
    }
  }

  Future<void> _clearLocalData() async {
    try {
      await _storageService.clearAuthData();
      await _storageService.clearUserData();
      _logger.d('Local storage cleared');
    } catch (e) {
      _logger.e('Error clearing local storage: $e');
      rethrow;
    }
  }
}