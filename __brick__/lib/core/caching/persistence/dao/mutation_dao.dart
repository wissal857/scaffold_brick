import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/caching/persistence/models/mutations.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';

import 'i_mutation_dao.dart';

part 'mutation_dao.g.dart';

@DriftAccessor(tables: [Mutations])
class MutationDao extends DatabaseAccessor<AppDatabase>
    with _$MutationDaoMixin
    implements IMutationDao {
  // this constructor is required so that the main database can create an instance
  // of this object.
  MutationDao(super.attachedDatabase);

  @override
  Future<void> deleteOperation(int id) {
    return (delete(mutations)..where((op) => op.id.equals(id))).go();
  }

  // @override
  // Future<MutationData> coalsceUpdates(
  //   List<MutationData> toDelete,
  //   MutationsCompanion newOperation,
  // ) {
  //   List<int> idsToDelete = toDelete.map((o) => o.id).toList();
  //   return transaction(() async {
  //     await batch((batch) {
  //       batch.deleteWhere(mutations, (op) => op.id.isIn(idsToDelete));
  //     });

  //     return await insertIfAbsent(newOperation);
  //   });
  // }

  @override
  Future<void> updateStatus(int id, MutationStatus newStatus) async {
    await (update(mutations)..where((o) => o.id.equals(id))).write(
      MutationsCompanion(status: Value(newStatus.label)),
    );
  }

  @override
  Future<List<MutationData>> getPending() async {
    return (select(
      mutations,
    )..where((o) => o.status.equals(MutationStatus.pending.label))).get();
  }

  @override
  Future<List<MutationData>> findByEntityTypeAndIdempotencyKey({
    required String entityType,
    required String idempotencyKey,
  }) {
    return (select(mutations)..where(
          (o) =>
              o.entityType.equals(entityType) &
              o.idempotencyKey.equals(idempotencyKey),
        ))
        .get();
  }

  @override
  Future<List<MutationData>> findByOperationTypeAndEntityTypeAndEntityId({
    required MutationType mutationType,
    required String entityType,
    required String entityId,
  }) {
    return (select(mutations)..where(
          (o) =>
              o.operationType.equals(mutationType.label) &
              o.entityType.equals(entityType) &
              o.entityId.equals(entityId),
        ))
        .get();
  }

  /// Inserts a new mutation if there are no pending
  /// matching mutations
  ///
  /// Throws CachingException.duplicateInsertOfMutation
  @override
  Future<MutationData> insertIfAbsent(MutationsCompanion mutation) async {
    // check if there is no duplicate insert operation
    if (!await _checkIfAbsent(mutation)) {
      throw CachingException.duplicateInsertOfMutation();
    }
    int newId = await into(mutations).insert(mutation);
    return (select(mutations)..where((o) => o.id.equals(newId))).getSingle();
  }

  // check if a matching mutation is absent
  Future<bool> _checkIfAbsent(MutationsCompanion mutation) async {
    switch (mutation.operationType.value) {
      case MutationType.create:
        if ((await findByEntityTypeAndIdempotencyKey(
          entityType: mutation.entityType.value,
          idempotencyKey: mutation.idempotencyKey.value!,
        )).isNotEmpty) {
          return false;
        }
        break;
      case MutationType.delete:
        if ((await findByOperationTypeAndEntityTypeAndEntityId(
          mutationType: MutationType.delete,
          entityType: mutation.entityType.value,
          entityId: mutation.entityId.value,
        )).isNotEmpty) {
          return false;
        }
        break;
      case MutationType.update:
        if (mutation.dirtyFields.value == null) return false;
        final updateOperations =
            await findByOperationTypeAndEntityTypeAndEntityId(
              mutationType: MutationType.update,
              entityType: mutation.entityType.value,
              entityId: mutation.entityId.value,
            );
        if (updateOperations.isNotEmpty) {
          // compare dirty fields
          return updateOperations
              .where(
                (m) =>
                    mutation.dirtyFields.value!.every(m.dirtyFields!.contains),
              )
              .isEmpty;
        }
        break;
    }
    return true;
  }
}
