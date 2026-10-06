import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:{{project_name}}/core/network/sorting/i_sort_by.dart';
import 'package:{{project_name}}/core/sorting/sort_direction.dart';

part 'network_paginated_query_params.freezed.dart';

@freezed
abstract class NetworkPaginatedQueryParams with _$NetworkPaginatedQueryParams {
  const factory NetworkPaginatedQueryParams({
    String? query,
    required int cursor,
    required int limit,
    ISortBy? sortBy,
    SortDirection? sortDirection,
  }) = _NetworkPaginatedQueryParams;
}
