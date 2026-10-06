import 'package:drift/drift.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:{{project_name}}/core/database/i_db_sort_by.dart';
import 'package:{{project_name}}/core/sorting/sort_direction.dart';

part 'db_paginated_query_params.freezed.dart';

@Freezed(genericArgumentFactories: true)
abstract class DbPaginatedQueryParams<T extends DataClass>
    with _$DbPaginatedQueryParams<T> {
  const factory DbPaginatedQueryParams({
    String? query,
    // takes the entire row in order to satisfy the constraint
    // that a cursor can represent any column that matches the sortBy column
    /// Represents the last seen database record
    required T cursor,
    required int limit,
    IDbSortBy? sortBy,
    SortDirection? sortDirection,
  }) = _DbPaginatedQueryParams<T>;
}
