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
  Future<List<MutationData>> findByOperationTypeAndEntityTypeAndEntityLocalId({
    required MutationType mutationType,
    required String entityType,
    required int entityLocalId,
  }) {
    return (select(mutations)..where(
          (o) =>
              o.operationType.equals(mutationType.label) &
              o.entityType.equals(entityType) &
              o.entityLocalId.equals(entityLocalId),
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
          entityType: mutation.entityType.value.label,
          idempotencyKey: mutation.idempotencyKey.value!,
        )).isNotEmpty) {
          return false;
        }
        break;
      case MutationType.delete:
        if ((await findByOperationTypeAndEntityTypeAndEntityLocalId(
          mutationType: MutationType.delete,
          entityType: mutation.entityType.value.label,
          entityLocalId: mutation.entityLocalId.value,
        )).isNotEmpty) {
          return false;
        }
        break;
      case MutationType.update:
        if (mutation.dirtyFields.value == null) return false;
        final updateOperations =
            await findByOperationTypeAndEntityTypeAndEntityLocalId(
              mutationType: MutationType.update,
              entityType: mutation.entityType.value.label,
              entityLocalId: mutation.entityLocalId.value,
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
