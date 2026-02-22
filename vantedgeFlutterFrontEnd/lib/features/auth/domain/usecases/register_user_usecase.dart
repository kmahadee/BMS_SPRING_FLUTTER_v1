import 'package:logger/logger.dart';
import 'package:vantedge/features/auth/domain/repositories/auth_repository.dart';
import '../../data/dto/user_registration_dto.dart';


class RegisterUserUseCase {
  final AuthRepository _repository;
  final Logger _logger = Logger();

  RegisterUserUseCase({
    required AuthRepository repository,
  }) : _repository = repository;

  Future<void> call(UserRegistrationDTO params) async {
    try {
      _logger.i('Executing register user use case for: ${params.email}');
      
      await _repository.registerUser(params);
      
      _logger.i('User registration completed successfully');
    } catch (e) {
      _logger.e('Register user use case failed: $e');
      rethrow;
    }
  }
}