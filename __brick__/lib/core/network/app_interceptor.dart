import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class AppInterceptor extends Interceptor {
  AppInterceptor();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add headers, authentication, etc.

    // TODO: Add auth token if available
    // final token = await getAuthToken();
    // if (token != null) {
    //   options.headers['Authorization'] = 'Bearer $token';
    // }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: trigger a gloal logout or a refresh token logic
      debugPrint("Session expired. Redirecting to login...");
    }
    handler.next(err);
  }
}
