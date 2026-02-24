import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/auth_interceptor.dart';
import 'package:vantedge/core/api/interceptors/error_interceptor.dart';
import 'package:vantedge/core/api/interceptors/logging_interceptor.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/core/storage/secure_storage_service.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  DioClient._internal();

  late final Dio _dio;
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  static const String baseUrl = 'http://192.168.0.115:8080';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  void initialize() {
    final storageService = SecureStorageService();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: connectTimeout),
        receiveTimeout: const Duration(milliseconds: receiveTimeout),
        sendTimeout: const Duration(milliseconds: sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(storageService),
      LoggingInterceptor(),
      ErrorInterceptor(_dio, storageService),
    ]);

    _logger.i('DioClient initialized with baseUrl: $baseUrl');
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      throw const NetworkException(
        message: 'No internet connection. Please check your network.',
      );
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      return _parseResponse<T>(response);
    } catch (e) {
      _logger.e('GET request failed: $e');
      rethrow;
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _parseResponse<T>(response);
    } catch (e) {
      _logger.e('POST request failed: $e');
      rethrow;
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _parseResponse<T>(response);
    } catch (e) {
      _logger.e('PUT request failed: $e');
      rethrow;
    }
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _parseResponse<T>(response);
    } catch (e) {
      _logger.e('PATCH request failed: $e');
      rethrow;
    }
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();

    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _parseResponse<T>(response);
    } catch (e) {
      _logger.e('DELETE request failed: $e');
      rethrow;
    }
  }

  T _parseResponse<T>(Response<Map<String, dynamic>> response) {
    final data = response.data;

    if (data == null) {
      throw Exception('Response data is null');
    }

    if (T == dynamic) {
      return data as T;
    }

    // if (data.containsKey('data')) {
    //   return data['data'] as T;
    // }

    return data as T;
  }

  Dio get dio => _dio;
}
