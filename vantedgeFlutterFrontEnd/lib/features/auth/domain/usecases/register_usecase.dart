import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';

import '../../../../core/utils/validators.dart';
import '../../data/dto/customer_registration_dto.dart';
import '../entities/customer_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;
  final Logger _logger = Logger();

  RegisterUseCase({
    required AuthRepository repository,
  }) : _repository = repository;

  Future<CustomerEntity> call(CustomerRegistrationDTO params) async {
    try {
      _logger.i('Executing register use case for: ${params.email}');

      _validateRegistrationData(params);

      final customerResponse = await _repository.register(params);

      final customerEntity = customerResponse.toEntity();

      _logger.i('Registration use case completed successfully');
      return customerEntity;
    } catch (e) {
      _logger.e('Registration use case failed: $e');
      rethrow;
    }
  }

  void _validateRegistrationData(CustomerRegistrationDTO params) {
    final errors = <String, String>{};

    final usernameError = Validators.validateUsername(params.username);
    if (usernameError != null) {
      errors['username'] = usernameError;
    }

    final passwordError = Validators.validatePassword(params.password);
    if (passwordError != null) {
      errors['password'] = passwordError;
    }

    final emailError = Validators.validateEmail(params.email);
    if (emailError != null) {
      errors['email'] = emailError;
    }

    final phoneError = Validators.validatePhone(params.phone);
    if (phoneError != null) {
      errors['phone'] = phoneError;
    }

    final firstNameError = Validators.validateRequired(params.firstName, 'First name');
    if (firstNameError != null) {
      errors['firstName'] = firstNameError;
    }

    final lastNameError = Validators.validateRequired(params.lastName, 'Last name');
    if (lastNameError != null) {
      errors['lastName'] = lastNameError;
    }

    final addressError = Validators.validateRequired(params.address, 'Address');
    if (addressError != null) {
      errors['address'] = addressError;
    }

    final cityError = Validators.validateRequired(params.city, 'City');
    if (cityError != null) {
      errors['city'] = cityError;
    }

    final stateError = Validators.validateRequired(params.state, 'State');
    if (stateError != null) {
      errors['state'] = stateError;
    }

    final zipCodeError = Validators.validateZipCode(params.zipCode);
    if (zipCodeError != null) {
      errors['zipCode'] = zipCodeError;
    }

    try {
      final dob = DateTime.parse(params.dateOfBirth);
      final ageError = Validators.validateAge(dob, 18);
      if (ageError != null) {
        errors['dateOfBirth'] = ageError;
      }
    } catch (e) {
      errors['dateOfBirth'] = 'Invalid date format';
    }

    if (errors.isNotEmpty) {
      _logger.w('Validation failed: $errors');
      throw BadRequestException(
        message: 'Validation failed',
        validationErrors: errors,
      );
    }

    _logger.d('Validation passed');
  }
}