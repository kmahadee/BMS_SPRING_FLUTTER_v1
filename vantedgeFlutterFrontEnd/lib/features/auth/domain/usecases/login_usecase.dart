import 'package:logger/logger.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/dto/login_request_dto.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  LoginUseCase({
    required AuthRepository repository,
    required SecureStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  Future<UserEntity> call(LoginRequestDTO params) async {
    try {
      _logger.i('Executing login use case for: ${params.username}');

      final authResponse = await _repository.login(params);

      final userEntity = authResponse.toEntity();

      await _saveUserData(authResponse.toJson());

      _logger.i('Login use case completed successfully');
      return userEntity;
    } catch (e) {
      _logger.e('Login use case failed: $e');
      rethrow;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storageService.saveUserData(userData);
      _logger.d('User data saved to storage');
    } catch (e) {
      _logger.w('Failed to save user data: $e');
    }
  }
}