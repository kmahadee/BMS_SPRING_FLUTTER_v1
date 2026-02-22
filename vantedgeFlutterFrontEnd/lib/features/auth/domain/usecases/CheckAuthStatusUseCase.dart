import 'package:logger/logger.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository _repository;
  final Logger _logger = Logger();

  CheckAuthStatusUseCase({
    required AuthRepository repository,
  }) : _repository = repository;

  Future<bool> call() async {
    try {
      _logger.d('Checking authentication status');

      final isAuthenticated = await _repository.isAuthenticated();

      _logger.d('Authentication status: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      _logger.e('Error checking authentication status: $e');
      return false;
    }
  }
}