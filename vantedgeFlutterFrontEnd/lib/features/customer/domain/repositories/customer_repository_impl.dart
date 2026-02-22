import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/constants/api_constants.dart';
import 'package:vantedge/features/auth/data/dto/customer_registration_dto.dart';
import 'package:vantedge/features/auth/data/dto/customer_response_dto.dart';
import 'package:vantedge/features/customer/data/models/customer_list_item_dto.dart';
import 'package:vantedge/features/customer/data/models/customer_update_request_dto.dart';
import 'customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  CustomerRepositoryImpl({
    required DioClient dioClient,
  }) : _dioClient = dioClient;

  @override
  Future<CustomerResponseDTO> createCustomer(CustomerRegistrationDTO request) async {
    try {
      _logger.i('Creating customer account for: ${request.email}');

      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiConstants.createCustomer,
        data: request.toJson(),
      );

      final customerData = CustomerResponseDTO.fromJson(response['data']);

      _logger.i('Customer account created successfully for: ${customerData.email}');
      return customerData;
    } catch (e) {
      _logger.e('Customer creation failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomerListItemDTO>> getAllCustomers() async {
    try {
      _logger.i('Fetching all customers');

      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiConstants.getAllCustomers,
      );

      final List<dynamic> customersList = response['data'] as List<dynamic>;
      final customers = customersList
          .map((json) => CustomerListItemDTO.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.i('Fetched ${customers.length} customers');
      return customers;
    } catch (e) {
      _logger.e('Failed to fetch customers: $e');
      rethrow;
    }
  }

  @override
  Future<CustomerResponseDTO> getCustomerById(int id) async {
    try {
      _logger.i('Fetching customer by ID: $id');

      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiConstants.getCustomerById(id),
      );

      final customer = CustomerResponseDTO.fromJson(response['data']);

      _logger.i('Customer fetched successfully: ${customer.customerId}');
      return customer;
    } catch (e) {
      _logger.e('Failed to fetch customer by ID: $e');
      rethrow;
    }
  }

  @override
  Future<CustomerResponseDTO> getCustomerByCustomerId(String customerId) async {
    try {
      _logger.i('Fetching customer by customer ID: $customerId');

      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiConstants.getCustomerByCustomerId(customerId),
      );

      final customer = CustomerResponseDTO.fromJson(response['data']);

      _logger.i('Customer fetched successfully: ${customer.customerId}');
      return customer;
    } catch (e) {
      _logger.e('Failed to fetch customer by customer ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomerListItemDTO>> getCustomersByStatus(String status) async {
    try {
      _logger.i('Fetching customers by status: $status');

      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiConstants.getCustomersByStatus(status),
      );

      final List<dynamic> customersList = response['data'] as List<dynamic>;
      final customers = customersList
          .map((json) => CustomerListItemDTO.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.i('Fetched ${customers.length} customers with status: $status');
      return customers;
    } catch (e) {
      _logger.e('Failed to fetch customers by status: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomerListItemDTO>> getCustomersByKycStatus(String kycStatus) async {
    try {
      _logger.i('Fetching customers by KYC status: $kycStatus');

      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiConstants.getCustomersByKycStatus(kycStatus),
      );

      final List<dynamic> customersList = response['data'] as List<dynamic>;
      final customers = customersList
          .map((json) => CustomerListItemDTO.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.i('Fetched ${customers.length} customers with KYC status: $kycStatus');
      return customers;
    } catch (e) {
      _logger.e('Failed to fetch customers by KYC status: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomerListItemDTO>> searchCustomers(String searchTerm) async {
    try {
      _logger.i('Searching customers with term: $searchTerm');

      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiConstants.searchCustomers,
        queryParameters: {'q': searchTerm},
      );

      final List<dynamic> customersList = response['data'] as List<dynamic>;
      final customers = customersList
          .map((json) => CustomerListItemDTO.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.i('Found ${customers.length} customers matching: $searchTerm');
      return customers;
    } catch (e) {
      _logger.e('Failed to search customers: $e');
      rethrow;
    }
  }

  @override
  Future<CustomerResponseDTO> updateCustomer(int id, CustomerUpdateRequestDTO request) async {
    try {
      _logger.i('Updating customer with ID: $id');

      final response = await _dioClient.put<Map<String, dynamic>>(
        ApiConstants.updateCustomer(id),
        data: request.toJson(),
      );

      final customer = CustomerResponseDTO.fromJson(response['data']);

      _logger.i('Customer updated successfully: ${customer.customerId}');
      return customer;
    } catch (e) {
      _logger.e('Failed to update customer: $e');
      rethrow;
    }
  }

  @override
  Future<CustomerResponseDTO> updateKycStatus(String customerId, String status) async {
    try {
      _logger.i('Updating KYC status for customer: $customerId to $status');

      final response = await _dioClient.patch<Map<String, dynamic>>(
        ApiConstants.updateKycStatus(customerId),
        queryParameters: {'status': status},
      );

      final customer = CustomerResponseDTO.fromJson(response['data']);

      _logger.i('KYC status updated successfully for: ${customer.customerId}');
      return customer;
    } catch (e) {
      _logger.e('Failed to update KYC status: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomer(int id) async {
    try {
      _logger.i('Soft deleting customer with ID: $id');

      await _dioClient.delete<Map<String, dynamic>>(
        ApiConstants.deleteCustomer(id),
      );

      _logger.i('Customer soft deleted successfully: $id');
    } catch (e) {
      _logger.e('Failed to delete customer: $e');
      rethrow;
    }
  }

  @override
  Future<void> hardDeleteCustomer(int id) async {
    try {
      _logger.i('Permanently deleting customer with ID: $id');

      await _dioClient.delete<Map<String, dynamic>>(
        ApiConstants.hardDeleteCustomer(id),
      );

      _logger.i('Customer permanently deleted successfully: $id');
    } catch (e) {
      _logger.e('Failed to permanently delete customer: $e');
      rethrow;
    }
  }
}