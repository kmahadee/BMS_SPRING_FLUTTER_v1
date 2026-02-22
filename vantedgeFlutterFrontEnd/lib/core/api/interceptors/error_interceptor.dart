import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/core/exceptions/auth_exceptions.dart';
import '../../storage/secure_storage_service.dart';


class ErrorInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  ErrorInterceptor(this._dio, this._storageService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final success = await _refreshToken();
        
        if (success) {
          final response = await _retryRequest(err.requestOptions);
          return handler.resolve(response);
        } else {
          await _handleLogout();
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const SessionExpiredException(
                message: 'Session expired. Please login again.',
              ),
            ),
          );
        }
      } catch (e) {
        await _handleLogout();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedException(
              message: 'Authentication failed',
              isTokenExpired: true,
            ),
          ),
        );
      }
    }

    final exception = _mapException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('No refresh token available');
        return false;
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storageService.saveAccessToken(data['accessToken']);
        await _storageService.saveRefreshToken(data['refreshToken']);
        _logger.i('Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      return false;
    }
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final token = await _storageService.getAccessToken();
    
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _storageService.clearAuthData();
      _logger.i('User logged out due to auth failure');
    } catch (e) {
      _logger.e('Error during logout: $e');
    }
  }

  Exception _mapException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Connection timeout. Please try again.',
          duration: error.type == DioExceptionType.connectionTimeout
              ? error.requestOptions.connectTimeout
              : error.type == DioExceptionType.sendTimeout
                  ? error.requestOptions.sendTimeout
                  : error.requestOptions.receiveTimeout,
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection. Please check your network.',
        );

      case DioExceptionType.badResponse:
        return _mapHttpException(error);

      case DioExceptionType.cancel:
        return const CancelledException(
          message: 'Request cancelled',
        );

      case DioExceptionType.unknown:
        return const NetworkException(
          message: 'An unexpected error occurred. Please try again.',
        );

      default:
        return const UnknownException(
          message: 'Something went wrong. Please try again.',
        );
    }
  }

  Exception _mapHttpException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final message = _extractErrorMessage(data);

    switch (statusCode) {
      case 400:
        final validationErrors = _extractValidationErrors(data);
        return BadRequestException(
          message: message ?? 'Invalid request. Please check your input.',
          validationErrors: validationErrors,
          data: data,
        );

      case 401:
        final isTokenExpired = _isTokenExpired(data);
        final isTokenInvalid = _isTokenInvalid(data);
        return UnauthorizedException(
          message: message ?? 'Unauthorized. Please login again.',
          isTokenExpired: isTokenExpired,
          isTokenInvalid: isTokenInvalid,
        );

      case 403:
        final requiredPermission = _extractRequiredPermission(data);
        return ForbiddenException(
          message: message ?? 'Access forbidden. Insufficient permissions.',
          requiredPermission: requiredPermission,
          data: data,
        );

      case 404:
        final resourceType = _extractResourceType(data);
        final resourceId = _extractResourceId(data);
        return NotFoundException(
          message: message ?? 'Resource not found.',
          resourceType: resourceType,
          resourceId: resourceId,
          data: data,
        );

      case 409:
        final conflictType = _extractConflictType(data);
        final conflictingResource = _extractConflictingResource(data);
        return ConflictException(
          message: message ?? 'Conflict. Resource already exists or has been modified.',
          conflictType: conflictType,
          conflictingResource: conflictingResource,
          data: data,
        );

      case 422:
        final errors = _extractValidationErrors(data);
        return UnprocessableEntityException(
          message: message ?? 'Unable to process the request.',
          errors: errors,
          data: data,
        );

      case 429:
        final retryAfter = _extractRetryAfter(error.response?.headers);
        return TooManyRequestsException(
          message: message ?? 'Too many requests. Please try again later.',
          retryAfter: retryAfter,
          data: data,
        );

      case 500:
        return ServerException(
          message: message ?? 'Internal server error. Please try again later.',
          serverStatusCode: 500,
          data: data,
        );

      case 501:
        return const ServerException(
          message: 'Feature not implemented.',
          serverStatusCode: 501,
        );

      case 502:
        return const ServerException(
          message: 'Bad gateway. Please try again later.',
          serverStatusCode: 502,
        );

      case 503:
        return const ServerException(
          message: 'Service unavailable. Please try again later.',
          serverStatusCode: 503,
        );

      case 504:
        return const ServerException(
          message: 'Gateway timeout. Please try again.',
          serverStatusCode: 504,
        );

      default:
        return ApiException(
          message: message ?? 'An error occurred. Please try again.',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is Map) {
        return data['message'] as String? ?? 
               data['error'] as String? ?? 
               data['msg'] as String?;
      }
      return data.toString();
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? _extractValidationErrors(dynamic data) {
    if (data is Map && data.containsKey('errors')) {
      final errors = data['errors'];
      if (errors is Map) {
        return Map<String, dynamic>.from(errors);
      }
    }
    return null;
  }

  String? _extractRequiredPermission(dynamic data) {
    if (data is Map) {
      return data['requiredPermission'] as String? ?? 
             data['required_permission'] as String?;
    }
    return null;
  }

  String? _extractResourceType(dynamic data) {
    if (data is Map) {
      return data['resourceType'] as String? ?? 
             data['resource_type'] as String?;
    }
    return null;
  }

  dynamic _extractResourceId(dynamic data) {
    if (data is Map) {
      return data['resourceId'] ?? data['resource_id'];
    }
    return null;
  }

  String? _extractConflictType(dynamic data) {
    if (data is Map) {
      return data['conflictType'] as String? ?? 
             data['conflict_type'] as String?;
    }
    return null;
  }

  dynamic _extractConflictingResource(dynamic data) {
    if (data is Map) {
      return data['conflictingResource'] ?? 
             data['conflicting_resource'];
    }
    return null;
  }

  int? _extractRetryAfter(Headers? headers) {
    if (headers == null) return null;
    
    final retryAfter = headers.value('retry-after');
    if (retryAfter != null) {
      return int.tryParse(retryAfter);
    }
    return null;
  }

  bool _isTokenExpired(dynamic data) {
    if (data is Map) {
      final reason = data['reason'] as String? ?? '';
      final error = data['error'] as String? ?? '';
      return reason.toLowerCase().contains('expired') || 
             error.toLowerCase().contains('expired');
    }
    return false;
  }

  bool _isTokenInvalid(dynamic data) {
    if (data is Map) {
      final reason = data['reason'] as String? ?? '';
      final error = data['error'] as String? ?? '';
      return reason.toLowerCase().contains('invalid') || 
             error.toLowerCase().contains('invalid');
    }
    return false;
  }
}