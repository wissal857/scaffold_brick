import 'package:dio/dio.dart';
import 'package:{{project_name}}/core/constants/app_constants.dart';
import 'package:{{project_name}}/core/logging/app_logger.dart';
import 'package:{{project_name}}/core/network/app_interceptor.dart';
import 'package:{{project_name}}/core/network/i_http_client.dart';

class HttpClient implements IHttpClient {
  late final Dio _dio;

  final _log = AppLogger.logger;

  HttpClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.kApiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors
    _dio.interceptors.add(AppInterceptor());
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (log) => _log.fine(log.toString()),
      ),
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, T>? queryParameters,
  }) async {
    return await _dio.get<T>(path, queryParameters: queryParameters);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    required T data,
    Map<String, T>? headers,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    required T data,
    Map<String, T>? headers,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }

  @override
  Future<Response<T>> delete<T>(String path, {Map<String, T>? headers}) async {
    return await _dio.delete<T>(path, options: Options(headers: headers));
  }
}
