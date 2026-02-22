import 'package:logger/logger.dart';
import 'package:vantedge/features/auth/data/dto/customer_registration_dto.dart';
import 'package:vantedge/features/auth/data/dto/customer_response_dto.dart';
import 'package:vantedge/features/customer/domain/repositories/customer_repository.dart';


class CreateCustomerUseCase {
  final CustomerRepository _repository;
  final Logger _logger = Logger();

  CreateCustomerUseCase({
    required CustomerRepository repository,
  }) : _repository = repository;

  Future<CustomerResponseDTO> call(CustomerRegistrationDTO params) async {
    try {
      _logger.i('Executing create customer use case for: ${params.email}');
      
      // You can add additional business logic here if needed
      // For example: validation, data transformation, etc.
      
      final customerResponse = await _repository.createCustomer(params);
      
      _logger.i('Customer created successfully: ${customerResponse.customerId}');
      return customerResponse;
    } catch (e) {
      _logger.e('Create customer use case failed: $e');
      rethrow;
    }
  }
}