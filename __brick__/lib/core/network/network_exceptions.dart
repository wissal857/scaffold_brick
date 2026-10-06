part of 'package:{{project_name}}/core/errors/app_exception.dart';

sealed class NetworkException extends AppException {
  const NetworkException._({required super.code, required super.message});
  const factory NetworkException.etagMissing() = ETagHeaderMissingException._;
}

final class ETagHeaderMissingException extends NetworkException {
  const ETagHeaderMissingException._()
    : super._(
        code: 'ETAG_MISSING',
        message: 'ETag header is missing from the response.',
      );
}
