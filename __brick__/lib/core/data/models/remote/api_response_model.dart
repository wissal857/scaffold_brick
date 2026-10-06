import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response_model.freezed.dart';
part 'api_response_model.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiResponseModel<T> with _$ApiResponseModel<T> {
  const factory ApiResponseModel({
    required String requestId,
    required bool success,
    required String message,
    T? data,
    String? timestamp,
    int? statusCode,
    String? error,
  }) = _ApiResponseModel<T>;

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) dataParser,
  ) => _$ApiResponseModelFromJson(json, dataParser);

  const ApiResponseModel._();
}
