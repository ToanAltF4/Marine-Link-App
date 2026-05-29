import 'package:dio/dio.dart';
import '../storage/secure_token_storage.dart';
import 'api_endpoints.dart';
import 'api_response.dart';

/// Dio-based HTTP client.
///
/// Automatically:
/// - Attaches Bearer token from secure storage.
/// - Parses responses into [ApiResponse].
/// - Maps Dio errors to [ApiException].
class ApiClient {
  late final Dio _dio;
  final SecureTokenStorage tokenStorage;

  ApiClient({required this.tokenStorage}) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor(tokenStorage));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => _log(o.toString()),
    ));
  }

  void _log(String message) {
    // ignore in release builds
    assert(() {
      // ignore: avoid_print
      print('[ApiClient] $message');
      return true;
    }());
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        message: 'Kết nối quá chậm. Vui lòng thử lại.',
        type: ApiExceptionType.network,
      );
    }

    final statusCode = e.response?.statusCode;
    final serverMessage = _extractMessage(e.response?.data);

    return switch (statusCode) {
      401 => ApiException(
          message: serverMessage ?? 'Phiên đăng nhập hết hạn.',
          type: ApiExceptionType.unauthorized,
          statusCode: statusCode,
        ),
      403 => ApiException(
          message: serverMessage ?? 'Bạn không có quyền thực hiện thao tác này.',
          type: ApiExceptionType.forbidden,
          statusCode: statusCode,
        ),
      404 => ApiException(
          message: serverMessage ?? 'Không tìm thấy dữ liệu.',
          type: ApiExceptionType.notFound,
          statusCode: statusCode,
        ),
      422 => ApiException(
          message: serverMessage ?? 'Dữ liệu không hợp lệ.',
          type: ApiExceptionType.validation,
          statusCode: statusCode,
        ),
      _ => ApiException(
          message: serverMessage ?? 'Lỗi hệ thống. Vui lòng thử lại.',
          type: ApiExceptionType.server,
          statusCode: statusCode,
        ),
    };
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}

/// Intercepts every request and attaches the Bearer JWT if available.
class _AuthInterceptor extends Interceptor {
  final SecureTokenStorage tokenStorage;

  _AuthInterceptor(this.tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Exception type for mapping HTTP errors to domain failures.
enum ApiExceptionType {
  network,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final ApiExceptionType type;
  final int? statusCode;

  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}
