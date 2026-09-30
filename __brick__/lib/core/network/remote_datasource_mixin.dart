import 'package:{{project_name}}/core/data/models/local/paginated_cache_model.dart';
import 'package:{{project_name}}/core/utils/paginated_query_params.dart';

import 'i_http_client.dart';

mixin RemoteDataSourceMixin<T> {
  IHttpClient get httpClient;

  /// fetches a paginated list
  Future<PaginatedCacheModel<T>> fetchPaginatedList({
    required String endpoint,
    required PaginatedQueryParams paginatedParams,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final queryParams = _buildQueryParameters(paginatedParams: paginatedParams);

    final response = await httpClient.get(
      endpoint,
      queryParameters: queryParams,
    );

    // Validate response data
    if (response.data == null) {
      throw Exception('API response data is null for endpoint: $endpoint');
    }
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Expected Map<String, dynamic> but got ${response.data.runtimeType} '
        'for endpoint: $endpoint',
      );
    }

    final paginatedResponse = PaginatedCacheModel<T>.fromJson(
      response.data!,
      (json) => parser(json as Map<String, dynamic>),
    );

    return paginatedResponse;
  }

  Future<T> fetchSingle({
    required String endpoint,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final response = await httpClient.get<Map<String, dynamic>>(endpoint);
    final result = parser(response.data!);

    return result;
  }

  Future<T> postItem({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final response = await httpClient.post<Map<String, dynamic>>(
      endpoint,
      data: data,
    );

    // Validate response data
    if (response.data == null) {
      throw Exception('API response data is null for endpoint: $endpoint');
    }
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Expected Map<String, dynamic> but got ${response.data.runtimeType} '
        'for endpoint: $endpoint',
      );
    }

    return parser(response.data!);
  }

  Future<void> putItem({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    await httpClient.put<void>(endpoint, data: data);
  }

  // converts query parameters model to a dataset suited for dio queries
  Map<String, dynamic> _buildQueryParameters({
    required PaginatedQueryParams paginatedParams,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = <String, dynamic>{};
    params['cursorId'] = paginatedParams.cursor;

    if (paginatedParams.query != null && paginatedParams.query!.isNotEmpty) {
      params['search'] = paginatedParams.query;
    }
    if (paginatedParams.limit != null) {
      params['limit'] = paginatedParams.limit;
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
}
