import 'package:drift/drift.dart';

import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/caching/persistence/models/scope_metadata.dart';
import 'i_scope_metadata_dao.dart';

part 'scope_metadata_dao.g.dart';

@DriftAccessor(tables: [ScopeMetadata])
class ScopeMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$ScopeMetadataDaoMixin
    implements IScopeMetadataDao {
  ScopeMetadataDao(super.attachedDatabase);

  @override
  Future<void> insertScopeMetadata(ScopeMetadataCompanion data) =>
      into(scopeMetadata).insert(data, mode: InsertMode.replace);

  @override
  Future<List<ScopeMetadataData>> getPendingOperations() =>
      (select(scopeMetadata)..where((t) => t.status.equals('PENDING'))).get();

  @override
  Future<void> updateSyncStatus(
    int id,
    String status, {
    String? errorMessage,
  }) => (update(scopeMetadata)..where((t) => t.id.equals(id))).write(
    ScopeMetadataCompanion(
      status: Value(status),
      //errorMessage: Value(errorMessage),
    ),
  );

  @override
  Future<void> incrementRetryCount(int id) async {
    final current = await (select(
      scopeMetadata,
    )..where((t) => t.id.equals(id))).getSingle();

    await (update(scopeMetadata)..where((t) => t.id.equals(id))).write(
      ScopeMetadataCompanion(retryCount: Value(current.retryCount + 1)),
    );
  }
}
