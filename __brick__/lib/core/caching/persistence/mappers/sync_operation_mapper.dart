import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

/// Converts an SyncRequest instance to a drift companion instance
/// suited for insert operations.
extension MutationCreateCompanionMapper on SyncCreateRequest {
  MutationsCompanion toCompanion() {
    final version = 1;
    return MutationsCompanion.insert(
      operationType: mutationType,
      entityType: entityType,
      entityId: entityId,
      idempotencyKey: Value(idempotencyKey),
      payload: SyncMutationRequestPayload(data: payload),
      etag: version.toString(),
      status: MutationStatus.pending.label,
      createdAt: timestamp,
    );
  }
}

extension MutationUpdateCompanionMapper on SyncUpdateRequest {
  MutationsCompanion toCompanion() {
    return MutationsCompanion.insert(
      operationType: mutationType,
      entityType: entityType,
      etag: etag,
      entityId: entityId,
      payload: SyncMutationRequestPayload(data: payload),
      previousPayload: Value(SyncMutationRequestPayload(data: previousPayload)),
      status: MutationStatus.pending.label,
      createdAt: timestamp,
      dirtyFields: Value(dirtyFields),
    );
  }
}

extension MutationDeleteCompanionMapper on SyncDeleteRequest {
  MutationsCompanion toCompanion() {
    return MutationsCompanion.insert(
      operationType: mutationType,
      entityType: entityType,
      etag: etag,
      entityId: entityId,
      payload: SyncMutationRequestPayload(data: payload),
      status: MutationStatus.pending.label,
      createdAt: timestamp,
    );
  }
}
