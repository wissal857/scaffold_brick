import 'package:drift/drift.dart';

/// Query-specific metadata: this will be used to keep
/// the metadata of a query that returns more than one entity
@DataClassName('QueryMetadataData')
@TableIndex(name: "idx_query_meta_next_sync", columns: {#nextSyncAt})
class QueryMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Unique query identifier (hash of query params, filters, pagination)
  /// Examples: "posts:all", "posts:user=123", "comments:post=456:page=1"
  TextColumn get queryKey => text().unique()();
  TextColumn get canonicalQuery => text()();
  IntColumn get etag => integer()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get nextSyncAt => dateTime()();
  IntColumn get syncCount => integer().withDefault(const Constant(0))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();

  /// Remote version to track delta syncs
  IntColumn get remoteVersion => integer().withDefault(const Constant(0))();

  /// Count of items cached for this query
  IntColumn get localCount => integer().withDefault(const Constant(0))();
}
