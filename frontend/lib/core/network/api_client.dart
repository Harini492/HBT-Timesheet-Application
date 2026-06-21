import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import '../errors/exceptions.dart';
import '../storage/token_storage.dart';

/// Thin wrapper around Dio with:
///  - automatic Authorization header injection
///  - a callback fired on 401 so the auth layer can force a logout
///  - exceptions normalized into AppException subtypes
class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  void Function()? onUnauthorized;

  ApiClient({required this.tokenStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _wrap(() => dio.get(path, queryParameters: query));
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return _wrap(() => dio.post(path, data: data));
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) {
    return _wrap(() => dio.put(path, data: data));
  }

  Future<Response<dynamic>> delete(String path) {
    return _wrap(() => dio.delete(path));
  }

  Future<Response<dynamic>> _wrap(Future<Response<dynamic>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Something went wrong. Please try again.';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }
    if (statusCode == 401) return UnauthorizedException(message);
    if (statusCode == 422 || statusCode == 400) return ValidationException(message);
    return ServerException(message);
  }
}
