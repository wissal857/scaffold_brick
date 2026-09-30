import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';

abstract interface class ILocalStateStore {
  /// Saves an entity with the create operation in
  /// a transaction
  Future<void> save({required SyncCreateRequest syncRequest});

  Future<void> delete({required SyncDeleteRequest syncRequest});

  Future<void> update({required SyncUpdateRequest syncRequest});

  //Future<void> deleteOperation(int operationId);

  // // updates the entity with server id and removes
  // // the operation from the database
  // Future<void> postRemoteSave({
  //   required int operationId,
  //   required int entityId,
  //   required int serverId,
  // });

  //Future<void> setOperationStatus(int operationId, MutationStatus newStatus);
}
