import 'package:vantedge/features/auth/data/dto/user_registration_dto.dart';

import '../../data/dto/auth_response_dto.dart';
import '../../data/dto/customer_registration_dto.dart';
import '../../data/dto/customer_response_dto.dart';
import '../../data/dto/login_request_dto.dart';

abstract class AuthRepository {
  Future<AuthResponseDTO> login(LoginRequestDTO request);

  Future<CustomerResponseDTO> register(CustomerRegistrationDTO request);

  Future<void> registerUser(UserRegistrationDTO request);

  Future<AuthResponseDTO> refreshToken(String refreshToken);

  Future<void> logout();

  Future<bool> validateToken();

  Future<bool> isAuthenticated();
}
