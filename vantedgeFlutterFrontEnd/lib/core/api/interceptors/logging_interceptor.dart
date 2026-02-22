import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
      _logger.d('Headers: ${options.headers}');
      _logger.d('Query Parameters: ${options.queryParameters}');
      if (options.data != null) {
        _logger.d('Body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
      _logger.d('Response Data: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.e(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      );
      _logger.e('Error Type: ${err.type}');
      _logger.e('Error Message: ${err.message}');
      if (err.response != null) {
        _logger.e('Error Response: ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}
