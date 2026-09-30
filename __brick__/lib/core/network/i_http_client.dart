import 'package:dio/dio.dart';

abstract class IHttpClient {
  Future<Response<T>> get<T>(String path, {Map<String, T>? queryParameters});

  Future<Response<T>> post<T>(
    String path, {
    required T data,
    Map<String, T>? headers,
  });

  Future<Response<T>> put<T>(
    String path, {
    required T data,
    Map<String, T>? headers,
  });

  Future<Response<T>> delete<T>(String path, {Map<String, T>? headers});
}
