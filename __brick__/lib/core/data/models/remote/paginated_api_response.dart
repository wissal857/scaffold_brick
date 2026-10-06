import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_api_response.freezed.dart';
part 'paginated_api_response.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class PaginatedApiResponse<T> with _$PaginatedApiResponse<T> {
  const factory PaginatedApiResponse({
    required List<T> data,
    required int total,
    @JsonKey(name: 'nextCursor') int? nextCursor,
  }) = _PaginatedApiResponse<T>;

  factory PaginatedApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) dataParser,
  ) => _$PaginatedApiResponseFromJson(json, dataParser);

  const PaginatedApiResponse._();
}
