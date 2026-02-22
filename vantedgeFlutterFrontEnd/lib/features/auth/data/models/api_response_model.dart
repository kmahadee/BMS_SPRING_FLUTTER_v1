import 'package:equatable/equatable.dart';

/// Generic API response wrapper for all API responses.
///
/// This model provides a standardized structure for API responses,
/// including success status, message, data payload, and timestamp.
///
/// Type parameter [T] represents the type of data contained in the response.
class ApiResponse<T> extends Equatable {
  /// Indicates whether the API request was successful
  final bool success;

  /// Human-readable message describing the response
  final String message;

  /// The actual data payload of the response (null if no data or error)
  final T? data;

  /// Timestamp of when the response was generated (ISO 8601 format)
  final String timestamp;

  /// Creates an API response.
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  /// Creates a successful [ApiResponse] with data.
  ///
  /// [data] - The response data
  /// [message] - Optional success message (default: 'Success')
  /// [timestamp] - Optional timestamp (default: current time)
  factory ApiResponse.success({
    required T data,
    String message = 'Success',
    String? timestamp,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      timestamp: timestamp ?? DateTime.now().toIso8601String(),
    );
  }

  /// Creates a failed [ApiResponse] without data.
  ///
  /// [message] - The error message
  /// [timestamp] - Optional timestamp (default: current time)
  factory ApiResponse.error({
    required String message,
    String? timestamp,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
      timestamp: timestamp ?? DateTime.now().toIso8601String(),
    );
  }

  /// Creates an [ApiResponse] from a JSON map.
  ///
  /// [json] - The JSON map containing the response data
  /// [fromJsonT] - Function to convert the data field from JSON to type T
  ///
  /// Example:
  /// ```dart
  /// final response = ApiResponse.fromJson(
  ///   jsonData,
  ///   (json) => UserDto.fromJson(json as Map<String, dynamic>),
  /// );
  /// ```
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Converts this [ApiResponse] to a JSON map.
  ///
  /// [toJsonT] - Optional function to convert the data field to JSON
  ///
  /// Returns a map that can be serialized to JSON
  Map<String, dynamic> toJson([Object? Function(T data)? toJsonT]) {
    return {
      'success': success,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'timestamp': timestamp,
    };
  }

  /// Creates a copy of this [ApiResponse] with optional field updates.
  ApiResponse<T> copyWith({
    bool? success,
    String? message,
    T? data,
    String? timestamp,
  }) {
    return ApiResponse<T>(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ApiResponse<$T>('
        'success: $success, '
        'message: $message, '
        'data: $data, '
        'timestamp: $timestamp)';
  }

  @override
  List<Object?> get props => [success, message, data, timestamp];

  /// Whether this response indicates an error
  bool get isError => !success;

  /// Whether this response contains data
  bool get hasData => data != null;

  /// Gets the data or throws an exception if not present
  T get dataOrThrow {
    if (data == null) {
      throw StateError('No data available in response');
    }
    return data as T;
  }

  /// Gets the data or returns a default value if not present
  T dataOr(T defaultValue) => data ?? defaultValue;

  /// Parses the timestamp to a DateTime object
  DateTime? get timestampAsDateTime {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Maps the data to a new type using a transformation function.
  ///
  /// [transform] - Function to transform the data
  ///
  /// Example:
  /// ```dart
  /// final stringResponse = intResponse.map((int value) => value.toString());
  /// ```
  ApiResponse<R> map<R>(R Function(T data) transform) {
    return ApiResponse<R>(
      success: success,
      message: message,
      data: data != null ? transform(data as T) : null,
      timestamp: timestamp,
    );
  }

  /// Transforms the response using different functions for success and error cases.
  ///
  /// [onSuccess] - Function to call if the response is successful
  /// [onError] - Function to call if the response is an error
  ///
  /// Example:
  /// ```dart
  /// final result = response.fold(
  ///   onSuccess: (data) => 'Success: $data',
  ///   onError: (message) => 'Error: $message',
  /// );
  /// ```
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message) onError,
  }) {
    if (success && data != null) {
      return onSuccess(data as T);
    } else {
      return onError(message);
    }
  }

  /// Executes a function with the data if successful, otherwise does nothing.
  ///
  /// [action] - Function to execute with the data
  ///
  /// Example:
  /// ```dart
  /// response.whenSuccess((data) {
  ///   print('Received data: $data');
  /// });
  /// ```
  void whenSuccess(void Function(T data) action) {
    if (success && data != null) {
      action(data as T);
    }
  }

  /// Executes a function with the error message if failed, otherwise does nothing.
  ///
  /// [action] - Function to execute with the error message
  ///
  /// Example:
  /// ```dart
  /// response.whenError((message) {
  ///   print('Error occurred: $message');
  /// });
  /// ```
  void whenError(void Function(String message) action) {
    if (!success) {
      action(message);
    }
  }
}

/// Extension methods for ApiResponse with List data
extension ApiResponseListExtension<T> on ApiResponse<List<T>> {
  /// Gets the number of items in the list, or 0 if data is null
  int get itemCount => data?.length ?? 0;

  /// Checks if the list is empty
  bool get isEmpty => data?.isEmpty ?? true;

  /// Checks if the list is not empty
  bool get isNotEmpty => data?.isNotEmpty ?? false;

  /// Gets the first item in the list or null if empty
  T? get firstOrNull => data?.isNotEmpty == true ? data!.first : null;

  /// Gets the last item in the list or null if empty
  T? get lastOrNull => data?.isNotEmpty == true ? data!.last : null;
}

/// Extension methods for ApiResponse with Map data
extension ApiResponseMapExtension<K, V> on ApiResponse<Map<K, V>> {
  /// Gets the number of entries in the map, or 0 if data is null
  int get entryCount => data?.length ?? 0;

  /// Checks if the map is empty
  bool get isEmpty => data?.isEmpty ?? true;

  /// Checks if the map is not empty
  bool get isNotEmpty => data?.isNotEmpty ?? false;

  /// Gets a value from the map by key, or null if not found
  V? getValue(K key) => data?[key];

  /// Checks if the map contains a key
  bool containsKey(K key) => data?.containsKey(key) ?? false;
}
