import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/sync_request_payload_converter.dart';

/// ScopeMetadata is used to store the metadata of a
/// scoped scope that can be triggered by network is available,
/// app lifcycle events or a scheduler
@DataClassName('ScopeMetadataData')
@TableIndex(name: "idx_scope_meta_scope", columns: {#scope})
@TableIndex(name: "idx_scope_meta_created", columns: {#createdAt})
class ScopeMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Flexible scope for global scopes (e.g., entityType, userId, orgId, workspace)
  /// Examples: "post", "comment:user123", "org:acme", "workspace:proj1"
  TextColumn get scope => text()();
  //TextColumn get entityType => text()(); // 'user', 'post', 'comment', etc.
  TextColumn get operation => text()(); // CREATE, UPDATE, DELETE
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  /// Version of the entity being scopeed
  IntColumn get etag => integer()();
  TextColumn get payload => text().map(const SyncPayloadConverter())();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get scopeedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastScopeError => text().nullable()();
  TextColumn get scopeStrategy => text().withDefault(const Constant('FULL'))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {scope},
  ];
}
