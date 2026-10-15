import 'package:dio/dio.dart';
import 'package:{{project_name}}/core/data/models/remote/api_response_model.dart';
import 'package:{{project_name}}/core/data/models/remote/paginated_api_response.dart';
import 'package:{{project_name}}/core/network/network_paginated_query_params.dart';

import 'i_http_client.dart';

mixin RemoteDataSourceMixin<T> {
  IHttpClient get httpClient;

  /// fetches a paginated list
  Future<PaginatedApiResponse<T>> fetchPaginatedList({
    required String endpoint,
    required NetworkPaginatedQueryParams paginatedParams,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final queryParams = _buildQueryParameters(paginatedParams: paginatedParams);

    final response = await httpClient.get(
      endpoint,
      queryParameters: queryParams,
    );

    _validateResponseData(response, endpoint);
    return _parsePaginatedApiResponseData(response, endpoint, parser);
  }

  Future<ApiResponseModel<T>> fetchSingle({
    required String endpoint,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final response = await httpClient.get(endpoint);
    return _parseApiResponseData(response, endpoint, parser);
  }

  Future<ApiResponseModel<T>> postItem({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final response = await httpClient.post(endpoint, data: data);
    return _parseApiResponseData(response, endpoint, parser);
  }

  Future<ApiResponseModel<T>> putItem({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final response = await httpClient.put(endpoint, data: data);
    return _parseApiResponseData(response, endpoint, parser);
  }

  // converts query parameters model to a dataset suited for dio queries
  Map<String, dynamic> _buildQueryParameters({
    required NetworkPaginatedQueryParams paginatedParams,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = <String, dynamic>{};
    params['cursor'] = paginatedParams.cursor;

    if (paginatedParams.query != null && paginatedParams.query!.isNotEmpty) {
      params['search'] = paginatedParams.query;
    }
    if (paginatedParams.sortBy != null) {
      params['sort_by'] = paginatedParams.sortBy?.label;
    }
    if (paginatedParams.sortDirection != null) {
      params['sort_order'] = paginatedParams.sortDirection;
    }
    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    return params;
  }

  void _validateResponseData(Response response, String endpoint) {
    if (response.data == null) {
      throw Exception('API response data is null for endpoint: $endpoint');
    }
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Expected Map<String, dynamic> but got ${response.data.runtimeType} '
        'for endpoint: $endpoint',
      );
    }
  }

  ApiResponseModel<T> _parseApiResponseData(
    Response response,
    String endpoint,
    T Function(Map<String, dynamic>) parser,
  ) {
    try {
      final parsedResponse = ApiResponseModel<T>.fromJson(
        response.data!,
        (json) => parser(json as Map<String, dynamic>),
      );
      return parsedResponse;
    } on FormatException {
      throw Exception('Failed to parse response data for enpoint: $endpoint');
    }
  }

  PaginatedApiResponse<T> _parsePaginatedApiResponseData(
    Response response,
    String endpoint,
    T Function(Map<String, dynamic>) parser,
  ) {
    try {
      final parsedResponse = PaginatedApiResponse<T>.fromJson(
        response.data!,
        (json) => parser(json as Map<String, dynamic>),
      );
      return parsedResponse;
    } on FormatException {
      throw Exception('Failed to parse response data for enpoint: $endpoint');
    }
  }
}
