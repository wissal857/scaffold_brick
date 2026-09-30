import 'package:{{project_name}}/core/database/app_db.dart';

enum RemoteMutationErrorType {
  connectionError,
  badRequest,
  forbidden,
  unknown,
  cancelled,
  missingHeader,
  unresolvedConflict,
}

sealed class RemoteMutationResponse {
  const RemoteMutationResponse._({required this.mutation});

  final MutationData mutation;

  const factory RemoteMutationResponse.error({
    required RemoteMutationErrorType errorType,
    required MutationData mutation,
  }) = RemoteMutationError._;

  const factory RemoteMutationResponse.conflict({
    required MutationData mutation,
    required String etag,
    required Map<String, dynamic> serverRepresentation,
  }) = RemoteMutationConflict._;

  const factory RemoteMutationResponse.success({
    required MutationData mutation,
    required Map<String, dynamic> responseData,
  }) = RemoteMutationSuccess._;

  const factory RemoteMutationResponse.createSuccess({
    required MutationData mutation,
    required String etag,
    required Map<String, dynamic> responseData,
  }) = RemoteMutationCreateSuccess._;
}

class RemoteMutationSuccess extends RemoteMutationResponse {
  const RemoteMutationSuccess._({
    required super.mutation,
    required this.responseData,
  }) : super._();

  final Map<String, dynamic> responseData;
}

final class RemoteMutationCreateSuccess extends RemoteMutationSuccess {
  const RemoteMutationCreateSuccess._({
    required super.mutation,
    required this.etag,
    required super.responseData,
  }) : super._();

  final String etag;
}

final class RemoteMutationError extends RemoteMutationResponse {
  const RemoteMutationError._({
    required this.errorType,
    required super.mutation,
  }) : super._();

  final RemoteMutationErrorType errorType;
}

final class RemoteMutationConflict extends RemoteMutationResponse {
  const RemoteMutationConflict._({
    required super.mutation,
    required this.etag,
    required this.serverRepresentation,
  }) : super._();

  final String etag;
  final Map<String, dynamic> serverRepresentation;
}
