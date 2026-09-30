import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_cache_model.freezed.dart';

@freezed
abstract class PaginatedCacheModel<T> with _$PaginatedCacheModel<T> {
  const factory PaginatedCacheModel({
    required List<T> data,
    required int total,
    required bool hasNext,
    int? nextCursor,
  }) = _PaginatedCacheModel<T>;

  const PaginatedCacheModel._();
}
