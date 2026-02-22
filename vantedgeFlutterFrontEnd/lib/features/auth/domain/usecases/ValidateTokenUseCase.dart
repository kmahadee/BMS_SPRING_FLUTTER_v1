import 'package:logger/logger.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../repositories/auth_repository.dart';

class ValidateTokenUseCase {
  final AuthRepository _repository;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  ValidateTokenUseCase({
    required AuthRepository repository,
    required SecureStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  Future<bool> call() async {
    try {
      _logger.d('Executing validate token use case');

      final hasToken = await _storageService.hasValidToken();
      
      if (!hasToken) {
        _logger.d('No valid token in storage');
        return false;
      }

      final isExpired = await _storageService.isTokenExpired();
      
      if (isExpired) {
        _logger.d('Token is expired');
        return false;
      }

      final isValid = await _repository.validateToken();

      _logger.d('Token validation result: $isValid');
      return isValid;
    } catch (e) {
      _logger.e('Token validation use case failed: $e');
      return false;
    }
  }
}