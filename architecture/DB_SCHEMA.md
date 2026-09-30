Plan: design a comprehensive Drift schema supporting the offline-first flows (read caching, write queuing, delta sync, conflict tracking, tombstones) + code examples.

Core schema tables (put in `lib/core/db/` or as part of your `AppDatabase`)

```dart
import 'package:drift/drift.dart';

// 1. SYNC METADATA TABLE (shared across all features)
@DataClassName("SyncMetadata")
class TSyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get resourceType => text()(); // "employee", "project", etc.
  IntColumn get resourceId => integer()(); // entity ID
  TextColumn get data => text()(); // JSON blob of latest canonical state
  TextColumn get etag => text().nullable()(); // last server ETag
  DateTimeColumn get lastSyncedAt => dateTime().nullable()(); // last successful sync
  DateTimeColumn get lastFetchedAt => dateTime().nullable()(); // last fetch attempt
  TextColumn get syncStatus => text().withDefault(const Constant("synced"))(); // synced, pending_sync, conflict, stale, failed
  IntColumn get version => integer().nullable()(); // optional local version for merge
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {resourceType, resourceId}, // one metadata record per resource
  ];
}

// 2. QUEUED OPERATIONS TABLE (pending writes)
@DataClassName("QueuedOperation")
class TQueuedOperation extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId => text().unique()(); // unique idempotency key
  TextColumn get resourceType => text()(); // "employee", "project"
  IntColumn get resourceId => integer().nullable()(); // null for create
  TextColumn get operationType => text()(); // create, update, delete, patch
  TextColumn get payload => text()(); // serialized write command (JSON)
  TextColumn get etagAtEditTime => text().nullable()(); // ETag when user made change (for If-Match)
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant("pending"))(); // pending, in_progress, completed, failed
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// 3. DELTA SYNC CHECKPOINTS TABLE (one per collection/scope)
@DataClassName("DeltaSyncCheckpoint")
class TDeltaSyncCheckpoint extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncScopeId => text().unique()(); // "employees", "projects:team-123", etc.
  TextColumn get syncToken => text().nullable()(); // server-issued opaque token
  TextColumn get deltaCursor => text().nullable()(); // pagination cursor for multi-page deltas
  IntColumn get lastSyncVersion => integer().nullable()(); // if API uses versions instead of tokens
  DateTimeColumn get lastFullResyncAt => dateTime().nullable()(); // when we last did a full snapshot
  BoolColumn get requiresFullResync => boolean().withDefault(const Constant(false))();
  IntColumn get deltaPageSize => integer().withDefault(const Constant(100))();
  DateTimeColumn get nextRefreshAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  IntColumn get refreshRetryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastRefreshError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// 4. TOMBSTONES TABLE (for tracking deletes in delta sync)
@DataClassName("Tombstone")
class TTombstone extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get resourceType => text()(); // "employee", "project"
  IntColumn get resourceId => integer()();
  DateTimeColumn get deletedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get retentionUntil => dateTime()(); // after this, safe to prune
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {resourceType, resourceId}, // one tombstone per deleted resource
  ];
}

// 5. CONFLICTS TABLE (for tracking unresolved conflicts)
@DataClassName("ConflictRecord")
class TConflict extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get resourceType => text()();
  IntColumn get resourceId => integer()();
  TextColumn get localData => text()(); // pending local change (JSON)
  TextColumn get remoteData => text()(); // latest server version (JSON)
  TextColumn get localEtag => text().nullable()(); // ETag of local change
  TextColumn get remoteEtag => text()(); // ETag of server version
  TextColumn get conflictResolution => text().nullable()(); // user choice: "local", "remote", or null if unresolved
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {resourceType, resourceId}, // one conflict per resource
  ];
}
```

Feature-specific entity table example (e.g., employees)

```dart
// Your existing Employee table, but with optional sync metadata columns:
@DataClassName("EmployeeData")
class TEmployee extends Table {
  IntColumn get id => integer().primary()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  // ... other fields

  // Metadata (could also live in TSyncMetadata instead if you want one table for all)
  TextColumn get syncStatus => text().withDefault(const Constant("synced"))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}
```

Drift AppDatabase definition (pseudo)

```dart
@DriftDatabase(tables: [
  TEmployee,
  // ... other feature tables
  TSyncMetadata,
  TQueuedOperation,
  TDeltaSyncCheckpoint,
  TTombstone,
  TConflict,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
```

Usage patterns (short examples)

**Cache a fetched record:**

```dart
await db.into(db.tSyncMetadata).insertOnConflictUpdate(
  SyncMetadataCompanion(
    resourceType: Value('employee'),
    resourceId: Value(123),
    data: Value(jsonEncode(employeeData)),
    etag: Value(responseEtag),
    lastSyncedAt: Value(DateTime.now()),
    syncStatus: Value('synced'),
  ),
);
```

**Queue a write:**

```dart
await db.into(db.tQueuedOperation).insert(
  QueuedOperationCompanion(
    operationId: Value(uuid.v4()),
    resourceType: Value('employee'),
    resourceId: Value(123),
    operationType: Value('update'),
    payload: Value(jsonEncode(updateCommand)),
    etagAtEditTime: Value(currentEtag),
    syncStatus: Value('pending'),
  ),
);
```

**Load delta checkpoint:**

```dart
final checkpoint = await (db.select(db.tDeltaSyncCheckpoint)
  ..where((t) => t.syncScopeId.equals('employees')))
  .getSingleOrNull();
```

**Record conflict:**

```dart
await db.into(db.tConflict).insertOnConflictUpdate(
  ConflictCompanion(
    resourceType: Value('employee'),
    resourceId: Value(123),
    localData: Value(jsonEncode(localPendingChange)),
    remoteData: Value(jsonEncode(serverVersion)),
    localEtag: Value(localEtag),
    remoteEtag: Value(serverEtag),
  ),
);
```

**Prune old tombstones:**

```dart
await (db.delete(db.tTombstone)
  ..where((t) => t.retentionUntil.isSmallerThanValue(DateTime.now())))
  .go();
```

Key design notes

- `TSyncMetadata` is generic (all resources in one table) for centralized cache tracking; alternatively, embed sync fields in each feature table.
- `TQueuedOperation` stores serialized payloads as JSON so the sync engine can replay them without knowing feature-specific types.
- `TDeltaSyncCheckpoint` per scope (not per-resource) to minimize checkpoint records and batch delta refreshes.
- `TTombstone` + `retentionUntil` ensures delete tombstones are kept long enough for delta safety.
- `TConflict` isolates unresolved conflicts so the UI can display them separately.
- All tables include `createdAt`, `updatedAt`, `lastAttemptAt` for observability and eviction policies.

If you want, I can: 1) Generate the full Drift migration code, 2) provide a repository helper to query sync state, or 3) show how to apply eviction policies. Which would help most?
