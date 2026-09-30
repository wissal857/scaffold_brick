Plan: remove delta-specific columns/tables and simplify to a full-sync model with TTL-based refresh scheduling.

**Changes to make (summary)**

1. **Drop `TDeltaSyncCheckpoint`** entirely — replace with simpler `TCollectionSyncMetadata` (per-collection refresh tracking)
2. **Simplify sync tracking** — just `lastFullSyncAt`, `nextRefreshAt`, `syncStatus` per collection
3. **Keep `TSyncMetadata`** for individual record caching (ETags still useful for conditional GETs)
4. **Simplify `TTombstone`** — less critical, but can keep for detecting deletes
5. **Keep `TQueuedOperation`** and `TConflict`\*\* unchanged — still needed for write queueing and conflict handling

Revised schema

```dart
import 'package:drift/drift.dart';

// 1. SYNC METADATA TABLE (per-record cache, unchanged)
@DataClassName("SyncMetadata")
class TSyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get resourceType => text()(); // "employee", "project", etc.
  IntColumn get resourceId => integer()();
  TextColumn get data => text()(); // JSON blob of latest canonical state
  TextColumn get etag => text().nullable()(); // for conditional GET on single item
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant("synced"))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {resourceType, resourceId},
  ];
}

// 2. COLLECTION SYNC METADATA (replaces TDeltaSyncCheckpoint)
@DataClassName("CollectionSyncMetadata")
class TCollectionSyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collectionId => text().unique()(); // "employees", "projects", etc.
  DateTimeColumn get lastFullSyncAt => dateTime().nullable()(); // when we last fetched all
  DateTimeColumn get nextRefreshAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get refreshRetryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastRefreshError => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant("synced"))(); // synced, syncing, failed, stale
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// 3. QUEUED OPERATIONS TABLE (unchanged)
@DataClassName("QueuedOperation")
class TQueuedOperation extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId => text().unique()();
  TextColumn get resourceType => text()();
  IntColumn get resourceId => integer().nullable()();
  TextColumn get operationType => text()(); // create, update, delete, patch
  TextColumn get payload => text()();
  TextColumn get etagAtEditTime => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant("pending"))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// 4. CONFLICTS TABLE (unchanged)
@DataClassName("ConflictRecord")
class TConflict extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get resourceType => text()();
  IntColumn get resourceId => integer()();
  TextColumn get localData => text()();
  TextColumn get remoteData => text()();
  TextColumn get localEtag => text().nullable()();
  TextColumn get remoteEtag => text()();
  TextColumn get conflictResolution => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {resourceType, resourceId},
  ];
}

// 5. TOMBSTONES (optional, simplified)
@DataClassName("Tombstone")
class TTombstone extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get resourceType => text()();
  IntColumn get resourceId => integer()();
  DateTimeColumn get deletedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {resourceType, resourceId},
  ];
}
```

Updated AppDatabase

```dart
@DriftDatabase(tables: [
  TEmployee,
  // ... other feature tables
  TSyncMetadata,
  TCollectionSyncMetadata,  // replaces TDeltaSyncCheckpoint
  TQueuedOperation,
  TConflict,
  TTombstone, // optional
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
```

Simplified usage patterns

**Initialize or refresh collection sync metadata:**

```dart
await db.into(db.tCollectionSyncMetadata).insertOnConflictUpdate(
  CollectionSyncMetadataCompanion(
    collectionId: Value('employees'),
    lastFullSyncAt: Value(DateTime.now()),
    nextRefreshAt: Value(DateTime.now().add(Duration(hours: 1))), // TTL
    syncStatus: Value('synced'),
  ),
);
```

**Check if collection needs refresh (TTL-based):**

```dart
final metadata = await (db.select(db.tCollectionSyncMetadata)
  ..where((t) => t.collectionId.equals('employees')))
  .getSingleOrNull();

final needsRefresh = metadata == null || metadata.nextRefreshAt.isBefore(DateTime.now());
```

**Fetch and replace entire collection (full sync):**

```dart
// 1. Fetch all from server
final employees = await api.getEmployees();

// 2. Transactionally clear old + insert new
await db.transaction(() async {
  await (db.delete(db.tSyncMetadata)
    ..where((t) => t.resourceType.equals('employee')))
    .go();

  for (final emp in employees) {
    await db.into(db.tSyncMetadata).insert(
      SyncMetadataCompanion(
        resourceType: Value('employee'),
        resourceId: Value(emp.id),
        data: Value(jsonEncode(emp)),
        syncStatus: Value('synced'),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  // 3. Update collection metadata
  await db.into(db.tCollectionSyncMetadata).insertOnConflictUpdate(
    CollectionSyncMetadataCompanion(
      collectionId: Value('employees'),
      lastFullSyncAt: Value(DateTime.now()),
      nextRefreshAt: Value(DateTime.now().add(Duration(hours: 1))),
      syncStatus: Value('synced'),
    ),
  );
});
```

**Key differences from delta-sync schema**

| Aspect                       | Delta Sync                       | Full Sync                          |
| ---------------------------- | -------------------------------- | ---------------------------------- |
| Per-collection sync tracking | `TDeltaSyncCheckpoint` (complex) | `TCollectionSyncMetadata` (simple) |
| Sync token / cursor          | Required                         | Not needed                         |
| Multi-page refresh           | Required                         | Not needed                         |
| Refresh scheduling           | Token-based invalidation         | TTL-based (simpler)                |
| Tombstone retention          | Critical                         | Optional                           |
| Complexity                   | High                             | Low                                |

**When to upgrade to delta sync:**

- Collection grows to thousands of records
- Network bandwidth or battery drain becomes critical
- User complaints about sync latency
- Server supports delta APIs

This simplified approach gives you a solid offline-first foundation without the complexity of delta tokens, cursor tracking, and token invalidation logic.
