import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:{{project_name}}/app/utils/entity_type.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';

part 'valid_mutation_data.freezed.dart';

@freezed
class ValidMutationData with _$ValidMutationData {
  @override
  final int id;
  @override
  final MutationType operationType;
  @override
  final EntityType entityType;
  @override
  final int? entityLocalId;
  @override
  final String? idempotencyKey;
  @override
  final Set<String>? dirtyFields;
  @override
  final String? entityRemoteId;
  @override
  final String? etag;
  @override
  final Map<String, dynamic>? payload;
  @override
  final Map<String, dynamic>? previousPayload;
  @override
  final MutationStatus status;

  const ValidMutationData._({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.payload,
    required this.status,
    this.entityLocalId,
    this.entityRemoteId,
    this.idempotencyKey,
    this.dirtyFields,
    this.etag,
    this.previousPayload,
  });

  factory ValidMutationData.fromData(MutationData input) {
    switch (input.operationType) {
      case MutationType.create:
        if (input.idempotencyKey == null || input.idempotencyKey!.isEmpty) {
          throw CachingException.corruptedMutationTable(
            message: 'Idempotency key missing from create mutation: $input',
          );
        }

        if (input.payload?.data == null) {
          throw CachingException.corruptedMutationTable(
            message: 'Payload missing from create mutation: $input',
          );
        }
        break;
      case MutationType.update:
        if (input.payload?.data == null ||
            input.previousPayload?.data == null) {
          throw CachingException.corruptedMutationTable(
            message:
                'Payload or Previous payload missing from update mutation: $input',
          );
        }

        if (input.etag == null) {
          throw CachingException.corruptedMutationTable(
            message: 'ETag missing from update mutation: $input',
          );
        }

        if (input.entityRemoteId == null) {
          throw CachingException.corruptedMutationTable(
            message: 'EntityRemoteId missing from update mutation: $input',
          );
        }

        if (input.dirtyFields == null) {
          throw CachingException.corruptedMutationTable(
            message: 'DirtyFields missing from update mutation: $input',
          );
        }

        break;
      case MutationType.delete:
        if (input.etag == null) {
          throw CachingException.corruptedMutationTable(
            message: 'ETag missing from update mutation: $input',
          );
        }

        if (input.entityRemoteId == null) {
          throw CachingException.corruptedMutationTable(
            message: 'EntityRemoteId missing from update mutation: $input',
          );
        }
        break;
    }

    return ValidMutationData._(
      id: input.id,
      operationType: input.operationType,
      entityType: input.entityType,
      payload: input.payload?.data,
      status: MutationStatus.values.byName(input.status),
      entityLocalId: input.entityLocalId,
      entityRemoteId: input.entityRemoteId,
      etag: input.etag,
      previousPayload: input.previousPayload?.data,
      dirtyFields: input.dirtyFields,
      idempotencyKey: input.idempotencyKey,
    );
  }
}
