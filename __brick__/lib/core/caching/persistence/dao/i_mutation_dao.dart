import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

abstract interface class IMutationDao {
  Future<List<MutationData>> getPending();
  Future<List<MutationData>> findByEntityTypeAndIdempotencyKey({
    required String entityType,
    required String idempotencyKey,
  });

  Future<List<MutationData>> findByOperationTypeAndEntityTypeAndEntityId({
    required MutationType mutationType,
    required String entityType,
    required String entityId,
  });

  /// Inserts a new mutation if there are no pending
  /// matching mutations
  ///
  /// Throws CachingException.duplicateInsertOfMutation
  Future<MutationData> insertIfAbsent(MutationsCompanion change);
  Future<void> deleteOperation(int id);

  // Future<MutationData> coalsceUpdates(
  //   List<MutationData> toDelete,
  //   MutationsCompanion newOperation,
  // );

  Future<void> updateStatus(int id, MutationStatus newStatus);
}
