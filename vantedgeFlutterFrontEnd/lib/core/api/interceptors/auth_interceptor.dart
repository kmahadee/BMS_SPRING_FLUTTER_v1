import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  static final List<String> _excludedPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/customers',
  ];

  AuthInterceptor(this._storageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    
    if (_shouldSkipAuth(path)) {
      _logger.d('Skipping auth for: $path');
      return handler.next(options);
    }

    try {
      final token = await _storageService.getAccessToken();
      
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        _logger.d('Authorization header added for: $path');
      } else {
        _logger.w('No access token found for: $path');
      }
    } catch (e) {
      _logger.e('Error adding auth header: $e');
    }

    handler.next(options);
  }

  bool _shouldSkipAuth(String path) {
    return _excludedPaths.any((excluded) => path.contains(excluded));
  }
}
