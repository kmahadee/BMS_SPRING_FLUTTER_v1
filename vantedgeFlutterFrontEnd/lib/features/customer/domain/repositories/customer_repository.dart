import 'package:vantedge/features/auth/data/dto/customer_registration_dto.dart';
import 'package:vantedge/features/auth/data/dto/customer_response_dto.dart';

import '../../data/models/customer_list_item_dto.dart';
import '../../data/models/customer_update_request_dto.dart';

abstract class CustomerRepository {
  // Create customer (public endpoint)
  Future<CustomerResponseDTO> createCustomer(CustomerRegistrationDTO request);
  
  // Get all customers (requires auth: ADMIN, EMPLOYEE, BRANCH_MANAGER)
  Future<List<CustomerListItemDTO>> getAllCustomers();
  
  // Get customer by database ID (requires auth, customers can only view own data)
  Future<CustomerResponseDTO> getCustomerById(int id);
  
  // Get customer by customer ID (requires auth, customers can only view own data)
  Future<CustomerResponseDTO> getCustomerByCustomerId(String customerId);
  
  // Get customers by status (requires auth: ADMIN, EMPLOYEE, BRANCH_MANAGER)
  Future<List<CustomerListItemDTO>> getCustomersByStatus(String status);
  
  // Get customers by KYC status (requires auth: ADMIN, EMPLOYEE, BRANCH_MANAGER)
  Future<List<CustomerListItemDTO>> getCustomersByKycStatus(String kycStatus);
  
  // Search customers (requires auth: ADMIN, EMPLOYEE, BRANCH_MANAGER)
  Future<List<CustomerListItemDTO>> searchCustomers(String searchTerm);
  
  // Update customer (requires auth, customers can only update own data)
  Future<CustomerResponseDTO> updateCustomer(int id, CustomerUpdateRequestDTO request);
  
  // Update KYC status (requires auth: ADMIN, EMPLOYEE, BRANCH_MANAGER)
  Future<CustomerResponseDTO> updateKycStatus(String customerId, String status);
  
  // Soft delete customer (requires auth: ADMIN, EMPLOYEE, BRANCH_MANAGER)
  Future<void> deleteCustomer(int id);
  
  // Hard delete customer (requires auth: ADMIN only)
  Future<void> hardDeleteCustomer(int id);
}