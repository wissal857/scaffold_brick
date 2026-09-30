import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:{{project_name}}/core/sorting/i_sort_by.dart';
import 'package:{{project_name}}/core/sorting/sort_direction.dart';

part 'paginated_query_params.freezed.dart';

@freezed
abstract class PaginatedQueryParams with _$PaginatedQueryParams {
  const factory PaginatedQueryParams({
    String? query,
    required int cursor,
    required int limit,
    ISortBy? sortBy,
    SortDirection? sortDirection,
  }) = _PaginatedQueryParams;
}
