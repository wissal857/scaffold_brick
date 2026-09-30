import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

abstract interface class ISyncStateStore {
  // Updates the sync status to completed and sets the server_id
  // with etag fields in the entity then deletes the mutation from db
  Future<void> commitRemoteCreate({
    required MutationData mutation,
    required int serverId,
    required String etag,
  });

  /// Updates the sync status of the entity
  Future<void> commitRemoteUpdate({required MutationData mutation});

  /// Updates the sync status of the entity
  Future<void> commitRemoteDelete({required MutationData mutation});

  /// Restores an entity to its previous state after a sync
  /// failure and deletes its asssociated operation from the db
  /// in one transaction.
  /// Restoring an entity works as follows:
  /// - If the operation is create the restore should delete it.
  /// - If it's delete the restore should switch the delete flag.
  /// - If it's update the restore should reset the dirty fields to their
  /// previous state.
  ///
  /// Throws PreviousPayloadMissingException and SqliteException
  Future<void> rollback({
    required MutationStatus syncStatus,
    required MutationData mutation,
  });

  Future<void> markInProgress(MutationData mutation);

  Future<void> applyConflictResolution({
    required MutationData mutation,
    required String etag,
    required Map<String, dynamic> resolvedData,
  });
}
