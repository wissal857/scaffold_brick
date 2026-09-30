# Sync Engine Components - Contract Documentation

## Overview

This document defines the complete contract for each component in the Flutter Drift sync engine architecture. Each component is responsible for a specific aspect of the synchronization process.

---

## 1. SyncCoordinator

### Purpose

The **SyncCoordinator** is the main orchestrator that coordinates all synchronization activities. It receives sync requests from the SyncEngine and delegates them to the appropriate sub-components (MutationSynchronizer and RefreshSynchronizer). It manages the overall sync workflow and ensures proper sequencing of operations.

### Responsibilities

- Receive sync requests and determine the sync strategy
- Coordinate mutation synchronization with the remote server
- Coordinate data refresh based on specified policies
- Manage sync metadata updates
- Handle the overall sync lifecycle
- Provide progress updates to the SyncEngine

### Contract

```dart
abstract class SyncCoordinator {
  /// Initialize the coordinator with required dependencies
  Future<void> initialize();

  /// Execute a complete sync operation based on the sync request
  ///
  /// [request] - The sync request containing type and optional query metadata
  /// [onProgress] - Callback function to report progress updates
  /// Returns [SyncResult] containing sync outcome and statistics
  Future<SyncResult> sync(
    SyncRequest request, {
    required Function(SyncProgress) onProgress,
  });

  /// Sync only pending mutations without refreshing data
  ///
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] containing mutation sync outcome
  Future<SyncResult> syncMutationsOnly({
    required Function(SyncProgress) onProgress,
  });

  /// Sync data refresh only without syncing mutations
  ///
  /// [queryMetadata] - Optional metadata for targeted refresh
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] containing refresh outcome
  Future<SyncResult> syncRefreshOnly(
    QueryMetadata? queryMetadata, {
    required Function(SyncProgress) onProgress,
  });

  /// Get the current state of the coordinator
  SyncCoordinatorState get state;

  /// Check if coordinator is currently syncing
  bool get isSyncing;

  /// Get mutation synchronizer instance
  MutationSynchronizer get mutationSynchronizer;

  /// Get refresh synchronizer instance
  RefreshSynchronizer get refreshSynchronizer;

  /// Pause synchronization temporarily
  Future<void> pause();

  /// Resume synchronization
  Future<void> resume();

  /// Cancel ongoing sync operation
  Future<void> cancel();

  /// Dispose resources
  Future<void> dispose();
}
```

---

## 2. MutationSynchronizer

### Purpose

The **MutationSynchronizer** handles the synchronization of local mutations (create, update, delete operations) with the remote server. It manages the operation queue, applies retry policies for failed operations, and resolves conflicts when local and remote changes conflict.

### Responsibilities

- Fetch pending mutations from the local database
- Send mutations to the remote server
- Handle operation queueing and prioritization
- Apply retry logic for failed operations
- Resolve conflicts between local and remote changes
- Update sync operation metadata with results
- Mark operations as successfully synced or conflicted

### Contract

```dart
abstract class MutationSynchronizer {
  /// Initialize the synchronizer
  Future<void> initialize();

  /// Synchronize all pending mutations
  ///
  /// [onProgress] - Callback to report progress
  /// Returns [SyncResult] with mutation sync outcome
  Future<SyncResult> synchronizePendingMutations({
    required Function(SyncProgress) onProgress,
  });

  /// Get the operation queue
  OperationQueue get operationQueue;

  /// Get the retry policy
  RetryPolicy get retryPolicy;

  /// Get the conflict resolver
  ConflictResolver get conflictResolver;

  /// Get count of pending operations
  Future<int> getPendingOperationCount();

  /// Get count of conflicted operations
  Future<int> getConflictedOperationCount();

  /// Clear all pending operations (use with caution)
  Future<void> clearPendingOperations();

  /// Get details of a specific operation
  ///
  /// [operationId] - The ID of the operation
  /// Returns [SyncOperation] or null if not found
  Future<SyncOperation?> getOperation(String operationId);

  /// Mark an operation as resolved
  ///
  /// [operationId] - The ID of the operation to mark as resolved
  /// [resolution] - The conflict resolution strategy applied
  Future<void> markOperationAsResolved(
    String operationId,
    ConflictResolution resolution,
  );

  /// Retry a failed operation
  ///
  /// [operationId] - The ID of the operation to retry
  /// Returns [SyncResult] for this specific retry attempt
  Future<SyncResult> retryOperation(String operationId);

  /// Dispose resources
  Future<void> dispose();
}
```

---

## 3. OperationQueue

### Purpose

The **OperationQueue** manages the queue of pending synchronization operations. It determines the order in which operations are sent to the server, supports prioritization, and ensures proper handling of dependent operations.

### Responsibilities

- Maintain an ordered queue of pending operations
- Support priority-based operation ordering
- Handle dependencies between operations
- Dequeue operations for synchronization
- Track operation status in the queue
- Support batch processing of operations

### Contract

```dart
abstract class OperationQueue {
  /// Initialize the operation queue
  Future<void> initialize();

  /// Enqueue an operation
  ///
  /// [operation] - The sync operation to queue
  /// [priority] - Priority level (default: normal)
  Future<void> enqueue(
    SyncOperation operation, {
    OperationPriority priority = OperationPriority.normal,
  });

  /// Dequeue the next operation to sync
  ///
  /// Returns [SyncOperation] or null if queue is empty
  Future<SyncOperation?> dequeue();

  /// Peek at the next operation without removing it
  ///
  /// Returns [SyncOperation] or null if queue is empty
  Future<SyncOperation?> peek();

  /// Get the next N operations without removing them
  ///
  /// [count] - Number of operations to retrieve
  /// Returns list of [SyncOperation]
  Future<List<SyncOperation>> peekBatch(int count);

  /// Get current queue size
  Future<int> getQueueSize();

  /// Check if queue is empty
  Future<bool> isEmpty();

  /// Requeue an operation (move to end of queue)
  ///
  /// [operation] - The operation to requeue
  /// [priority] - New priority level
  Future<void> requeue(
    SyncOperation operation, {
    OperationPriority priority = OperationPriority.normal,
  });

  /// Remove an operation from queue
  ///
  /// [operationId] - The ID of the operation to remove
  /// Returns true if operation was removed, false if not found
  Future<bool> remove(String operationId);

  /// Clear entire queue
  Future<void> clear();

  /// Get all operations in queue
  Future<List<SyncOperation>> getAllOperations();

  /// Update operation status in queue
  ///
  /// [operationId] - The ID of the operation
  /// [status] - New status
  Future<void> updateOperationStatus(
    String operationId,
    SyncOperationStatus status,
  );

  /// Dispose resources
  Future<void> dispose();
}

enum OperationPriority { low, normal, high, critical }
enum SyncOperationStatus { pending, inProgress, completed, failed, conflicted }
```

---

## 4. RetryPolicy

### Purpose

The **RetryPolicy** defines the strategy for retrying failed synchronization operations. It determines how many times an operation should be retried, what delays should be applied between retries, and when an operation should be considered permanently failed.

### Responsibilities

- Determine if an operation should be retried
- Calculate delay before the next retry attempt
- Track retry attempt counts
- Implement exponential backoff or other backoff strategies
- Define maximum retry limits
- Handle different error types (network, server, validation)

### Contract

```dart
abstract class RetryPolicy {
  /// Initialize the retry policy
  Future<void> initialize();

  /// Check if an operation should be retried
  ///
  /// [operation] - The failed sync operation
  /// [attemptCount] - Number of retry attempts so far
  /// [lastError] - The error that caused the failure
  /// Returns true if operation should be retried, false otherwise
  bool shouldRetry(
    SyncOperation operation,
    int attemptCount,
    dynamic lastError,
  );

  /// Get the delay before the next retry attempt
  ///
  /// [attemptCount] - Number of retry attempts so far
  /// [lastError] - The error that caused the failure
  /// Returns [Duration] to wait before retrying
  Duration getRetryDelay(int attemptCount, dynamic lastError);

  /// Get the maximum number of retry attempts allowed
  ///
  /// [operation] - The sync operation
  /// Returns maximum retry count
  int getMaxRetryAttempts(SyncOperation operation);

  /// Check if an error is retryable
  ///
  /// [error] - The error to check
  /// Returns true if error can be retried, false if permanent
  bool isRetryableError(dynamic error);

  /// Get human-readable description of retry policy
  String getDescription();

  /// Dispose resources
  Future<void> dispose();
}
```

---

## 5. ConflictResolver

### Purpose

The **ConflictResolver** handles conflicts that arise when a local mutation cannot be applied to the server state (e.g., the server has a newer version, or there are permission issues). It implements strategies to resolve these conflicts automatically or by deferring to higher-level logic.

### Responsibilities

- Detect conflict conditions
- Implement conflict resolution strategies (Last-Write-Wins, Server-Wins, Client-Wins, Manual)
- Apply conflict resolution and update local data accordingly
- Track resolved conflicts
- Provide conflict details for manual resolution UI
- Log conflict metrics for analytics

### Contract

```dart
abstract class ConflictResolver {
  /// Initialize the conflict resolver
  Future<void> initialize();

  /// Check if two versions of data are in conflict
  ///
  /// [localData] - The local version of the data
  /// [remoteData] - The remote version of the data
  /// [operation] - The sync operation that caused the conflict
  /// Returns true if conflict is detected
  bool detectConflict(
    dynamic localData,
    dynamic remoteData,
    SyncOperation operation,
  );

  /// Resolve a conflict using the configured strategy
  ///
  /// [operation] - The sync operation in conflict
  /// [localData] - The local version of the data
  /// [remoteData] - The remote version of the data
  /// [strategy] - Resolution strategy to apply
  /// Returns [ConflictResolution] containing the resolution result
  Future<ConflictResolution> resolve(
    SyncOperation operation,
    dynamic localData,
    dynamic remoteData,
    ConflictResolutionStrategy strategy,
  );

  /// Get the default conflict resolution strategy
  ConflictResolutionStrategy getDefaultStrategy();

  /// Get available resolution strategies for an operation
  ///
  /// [operation] - The sync operation
  /// Returns list of available [ConflictResolutionStrategy]
  List<ConflictResolutionStrategy> getAvailableStrategies(
    SyncOperation operation,
  );

  /// Get all unresolved conflicts
  ///
  /// Returns list of [SyncOperation] with conflict status
  Future<List<SyncOperation>> getUnresolvedConflicts();

  /// Get details of a specific conflict
  ///
  /// [operationId] - The ID of the operation in conflict
  /// Returns [ConflictDetails] or null if not found
  Future<ConflictDetails?> getConflictDetails(String operationId);

  /// Apply a manual conflict resolution
  ///
  /// [operationId] - The ID of the conflicted operation
  /// [resolution] - The resolution to apply
  /// Returns true if successfully applied
  Future<bool> applyManualResolution(
    String operationId,
    ConflictResolution resolution,
  );

  /// Get conflict statistics
  ///
  /// Returns [ConflictStats] with conflict metrics
  Future<ConflictStats> getConflictStats();

  /// Dispose resources
  Future<void> dispose();
}

enum ConflictResolutionStrategy {
  serverWins,      // Keep remote data, discard local changes
  clientWins,      // Keep local data, overwrite remote
  lastWriteWins,   // Keep whichever was modified most recently
  merge,           // Merge both versions (field-level)
  manual,          // Defer to user for resolution
  custom,          // Custom resolution logic
}
```

---

## 6. RefreshSynchronizer

### Purpose

The **RefreshSynchronizer** handles the refresh of data from the remote server. It determines which data needs to be refreshed based on cache validity, applies refresh policies, and coordinates the execution of sync strategies (full or delta sync).

### Responsibilities

- Determine which data entities need refresh
- Check cache validity and TTL
- Apply refresh policies (when to refresh, what to refresh)
- Coordinate with sync strategy executor for actual data fetching
- Update query metadata with refresh timestamps
- Track refresh history and statistics
- Handle partial and selective refreshes

### Contract

```dart
abstract class RefreshSynchronizer {
  /// Initialize the synchronizer
  Future<void> initialize();

  /// Refresh all data entities
  ///
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] with refresh outcome
  Future<SyncResult> refreshAll({
    required Function(SyncProgress) onProgress,
  });

  /// Refresh specific data for a query
  ///
  /// [queryMetadata] - Metadata for the specific query to refresh
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] with refresh outcome
  Future<SyncResult> refreshForQuery(
    QueryMetadata queryMetadata, {
    required Function(SyncProgress) onProgress,
  });

  /// Refresh specific entity types
  ///
  /// [entityTypes] - List of entity type identifiers to refresh
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] with refresh outcome
  Future<SyncResult> refreshEntities(
    List<String> entityTypes, {
    required Function(SyncProgress) onProgress,
  });

  /// Get the refresh policy
  RefreshPolicy get refreshPolicy;

  /// Get the sync strategy executor
  SyncStrategyExecutor get syncStrategyExecutor;

  /// Check if data for an entity type should be refreshed
  ///
  /// [entityType] - The entity type identifier
  /// Returns true if refresh is needed
  Future<bool> shouldRefresh(String entityType);

  /// Check if data for a specific query should be refreshed
  ///
  /// [queryMetadata] - The query metadata to check
  /// Returns true if refresh is needed
  Future<bool> shouldRefreshQuery(QueryMetadata queryMetadata);

  /// Get refresh status for all tracked entities
  ///
  /// Returns map of entityType to [RefreshStatus]
  Future<Map<String, RefreshStatus>> getRefreshStatus();

  /// Get refresh history for an entity type
  ///
  /// [entityType] - The entity type identifier
  /// [limit] - Maximum number of history entries to return
  /// Returns list of [RefreshHistoryEntry]
  Future<List<RefreshHistoryEntry>> getRefreshHistory(
    String entityType, {
    int limit = 10,
  });

  /// Manually mark an entity as needing refresh
  ///
  /// [entityType] - The entity type to mark as stale
  Future<void> markAsStale(String entityType);

  /// Get refresh statistics
  ///
  /// Returns [RefreshStats] with refresh metrics
  Future<RefreshStats> getRefreshStats();

  /// Dispose resources
  Future<void> dispose();
}
```

---

## 7. RefreshPolicy

### Purpose

The **RefreshPolicy** defines when and how data should be refreshed from the remote server. It considers factors like time-to-live (TTL), user interaction patterns, data importance, and network conditions to determine optimal refresh timing.

### Responsibilities

- Define TTL for different data types
- Determine when cached data is stale
- Consider network conditions in refresh decisions
- Support different refresh policies (time-based, event-based, manual)
- Track last refresh times
- Implement smart refresh timing to minimize network usage

### Contract

````dart
abstract class RefreshPolicy {
  /// Initialize the refresh policy
  Future<void> initialize();

  /// Check if data for an entity type is stale
  ///
  /// [entityType] - The entity type to check
  /// [lastRefreshTime] - Timestamp of last refresh
  /// Returns true if data is considered stale
  bool isStale(String entityType, DateTime lastRefreshTime);

  /// Get the TTL for an entity type
  ///
  /// [entityType] - The entity type identifier
  ///
## 7. RefreshPolicy (continued)

```dart
  /// Get the TTL for an entity type
  ///
  /// [entityType] - The entity type identifier
  /// Returns [Duration] representing time-to-live
  Duration getTTL(String entityType);

  /// Check if refresh should occur based on network conditions
  ///
  /// [entityType] - The entity type to check
  /// [networkQuality] - Current network quality assessment
  /// Returns true if refresh should proceed despite network conditions
  bool shouldRefreshGivenNetworkConditions(
    String entityType,
    NetworkQuality networkQuality,
  );

  /// Check if refresh should occur based on current time
  ///
  /// [entityType] - The entity type to check
  /// Returns true if time-based refresh criteria are met
  bool shouldRefreshByTime(String entityType);

  /// Check if refresh should occur based on user interaction
  ///
  /// [entityType] - The entity type to check
  /// [lastUserInteractionTime] - Time of last user interaction
  /// Returns true if user interaction threshold is met
  bool shouldRefreshByUserInteraction(
    String entityType,
    DateTime lastUserInteractionTime,
  );

  /// Get suggested refresh interval for an entity type
  ///
  /// [entityType] - The entity type identifier
  /// Returns [Duration] representing recommended refresh interval
  Duration getRefreshInterval(String entityType);

  /// Set custom TTL for an entity type
  ///
  /// [entityType] - The entity type identifier
  /// [ttl] - New TTL duration
  Future<void> setCustomTTL(String entityType, Duration ttl);

  /// Get the refresh policy mode
  ///
  /// Returns [RefreshPolicyMode] (aggressive, balanced, conservative)
  RefreshPolicyMode get mode;

  /// Set the refresh policy mode
  ///
  /// [mode] - New refresh policy mode
  Future<void> setMode(RefreshPolicyMode mode);

  /// Get human-readable description of the policy
  String getDescription();

  /// Dispose resources
  Future<void> dispose();
}

enum RefreshPolicyMode {
  aggressive,   // Refresh frequently, prioritize freshness
  balanced,     // Balance between freshness and network usage
  conservative, // Refresh infrequently, prioritize battery/bandwidth
}

enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  offline,
}
````

---

## 8. SyncStrategyExecutor

### Purpose

The **SyncStrategyExecutor** executes the actual data fetching and synchronization from the remote server. It supports different sync strategies (full sync and delta sync) and handles the download, processing, and storage of remote data into the local database.

### Responsibilities

- Execute full sync strategy (fetch all data for an entity)
- Execute delta sync strategy (fetch only changed data)
- Fetch data from remote API
- Parse and transform remote data
- Store fetched data in local database
- Handle large data sets with pagination/batching
- Update sync metadata with fetch results
- Manage bandwidth and performance

### Contract

```dart
abstract class SyncStrategyExecutor {
  /// Initialize the executor
  Future<void> initialize();

  /// Execute full sync for an entity type
  ///
  /// [entityType] - The entity type to fully sync
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] with full sync outcome
  Future<SyncResult> executeFullSync(
    String entityType, {
    required Function(SyncProgress) onProgress,
  });

  /// Execute delta sync for an entity type
  ///
  /// [entityType] - The entity type to delta sync
  /// [since] - Timestamp to fetch changes since this time
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] with delta sync outcome
  Future<SyncResult> executeDeltaSync(
    String entityType,
    DateTime since, {
    required Function(SyncProgress) onProgress,
  });

  /// Execute full sync for a specific query
  ///
  /// [queryMetadata] - Metadata containing query details
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] with query sync outcome
  Future<SyncResult> executeFullSyncForQuery(
    QueryMetadata queryMetadata, {
    required Function(SyncProgress) onProgress,
  });

  /// Execute delta sync for a specific query
  ///
  /// [queryMetadata] - Metadata containing query details
  /// [since] - Timestamp to fetch changes since this time
  /// [onProgress] - Callback for progress updates
  /// Returns [SyncResult] with query sync outcome
  Future<SyncResult> executeDeltaSyncForQuery(
    QueryMetadata queryMetadata,
    DateTime since, {
    required Function(SyncProgress) onProgress,
  });

  /// Determine the best sync strategy for an entity
  ///
  /// [entityType] - The entity type identifier
  /// [lastSyncTime] - Time of last sync, null if never synced
  /// Returns [SyncStrategy] (full or delta)
  SyncStrategy determineSyncStrategy(
    String entityType,
    DateTime? lastSyncTime,
  );

  /// Check if delta sync is supported for an entity type
  ///
  /// [entityType] - The entity type identifier
  /// Returns true if delta sync is available
  bool isDeltaSyncSupported(String entityType);

  /// Get estimated data size for full sync
  ///
  /// [entityType] - The entity type identifier
  /// Returns estimated size in bytes
  Future<int> estimateFullSyncSize(String entityType);

  /// Get estimated data size for delta sync
  ///
  /// [entityType] - The entity type identifier
  /// [since] - Timestamp for delta calculation
  /// Returns estimated size in bytes
  Future<int> estimateDeltaSyncSize(String entityType, DateTime since);

  /// Cancel ongoing sync operation
  ///
  /// Returns true if operation was cancelled
  bool cancel();

  /// Get sync strategy statistics
  ///
  /// Returns [SyncStrategyStats] with execution metrics
  Future<SyncStrategyStats> getStats();

  /// Dispose resources
  Future<void> dispose();
}

enum SyncStrategy {
  full,   // Fetch all data for entity type
  delta,  // Fetch only changed data since last sync
}
```

---

## 9. CacheValidator

### Purpose

The **CacheValidator** periodically validates the integrity and freshness of cached data in the local database. It checks if cached data meets TTL requirements, detects stale data, and coordinates with the RefreshSynchronizer to refresh expired data.

### Responsibilities

- Validate TTL for all cached data entities
- Detect stale data based on refresh policies
- Track validation history and statistics
- Identify entities that need refresh
- Perform background validation without blocking
- Report validation results to SyncEngine
- Support selective validation of specific entities

### Contract

```dart
abstract class CacheValidator {
  /// Initialize the cache validator
  Future<void> initialize();

  /// Validate all cached data
  ///
  /// Returns [ValidationResult] with overall validation outcome
  Future<ValidationResult> validateAllMetadata();

  /// Validate a specific entity type
  ///
  /// [entityType] - The entity type to validate
  /// Returns [ValidationResult] for this entity
  Future<ValidationResult> validateEntity(String entityType);

  /// Validate a specific query metadata
  ///
  /// [queryMetadata] - The query metadata to validate
  /// Returns [ValidationResult] for this query
  Future<ValidationResult> validateQuery(QueryMetadata queryMetadata);

  /// Check if a specific entity is valid
  ///
  /// [entityType] - The entity type to check
  /// Returns true if entity cache is valid
  Future<bool> isEntityValid(String entityType);

  /// Check if a specific query cache is valid
  ///
  /// [queryMetadata] - The query metadata to check
  /// Returns true if query cache is valid
  Future<bool> isQueryValid(QueryMetadata queryMetadata);

  /// Get list of stale entities
  ///
  /// Returns list of entity type identifiers that are stale
  Future<List<String>> getStaleEntities();

  /// Get list of valid entities
  ///
  /// Returns list of entity type identifiers that are valid
  Future<List<String>> getValidEntities();

  /// Get validation status for all tracked entities
  ///
  /// Returns map of entityType to [ValidationStatus]
  Future<Map<String, ValidationStatus>> getValidationStatus();

  /// Get validation history for an entity
  ///
  /// [entityType] - The entity type identifier
  /// [limit] - Maximum number of entries to return
  /// Returns list of [ValidationHistoryEntry]
  Future<List<ValidationHistoryEntry>> getValidationHistory(
    String entityType, {
    int limit = 20,
  });

  /// Start continuous background validation
  ///
  /// [interval] - How often to validate (default: every 5 minutes)
  Future<void> startBackgroundValidation({
    Duration interval = const Duration(minutes: 5),
  });

  /// Stop continuous background validation
  Future<void> stopBackgroundValidation();

  /// Get validation statistics
  ///
  /// Returns [ValidationStats] with validation metrics
  Future<ValidationStats> getValidationStats();

  /// Mark an entity as manually invalidated
  ///
  /// [entityType] - The entity type to invalidate
  Future<void> invalidateEntity(String entityType);

  /// Mark all entities as manually invalidated
  Future<void> invalidateAll();

  /// Dispose resources
  Future<void> dispose();
}

class ValidationResult {
  final bool isValid;
  final String entityType;
  final DateTime validatedAt;
  final DateTime? expiresAt;
  final String? reason;

  ValidationResult({
    required this.isValid,
    required this.entityType,
    required this.validatedAt,
    this.expiresAt,
    this.reason,
  });
}

enum ValidationStatus {
  valid,
  expired,
  neverValidated,
  invalidated,
}
```

---

## 10. Supporting Models and Enums

### Data Models

These models are already defined in your codebase, but here's a summary of their expected structure:

```dart
/// Metadata for tracking sync operations
class SyncMetadata {
  final String id;
  final String entityType;
  final DateTime lastSyncTime;
  final DateTime? nextScheduledSync;
  final int totalSyncAttempts;
  final int lastSyncAttemptStatus; // 0=pending, 1=success, 2=failed
  final String? lastSyncError;
  final int? lastSyncOperationCount;

  SyncMetadata({
    required this.id,
    required this.entityType,
    required this.lastSyncTime,
    this.nextScheduledSync,
    required this.totalSyncAttempts,
    required this.lastSyncAttemptStatus,
    this.lastSyncError,
    this.lastSyncOperationCount,
  });
}

/// Metadata for tracking individual query caches
class QueryMetadata {
  final String id;
  final String queryKey;
  final String entityType;
  final String queryParams; // JSON string of query parameters
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final DateTime lastRefreshedAt;
  final int? cacheValidityDuration; // in seconds
  final int accessCount;
  final bool isValid;

  QueryMetadata({
    required this.id,
    required this.queryKey,
    required this.entityType,
    required this.queryParams,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.lastRefreshedAt,
    this.cacheValidityDuration,
    required this.accessCount,
    required this.isValid,
  });
}

/// Individual sync operation (mutation)
class SyncOperation {
  final String id;
  final String entityType;
  final SyncOperationType type; // create, update, delete
  final String localId;
  final String? remoteId;
  final String operationData; // JSON data
  final DateTime createdAt;
  final DateTime? syncedAt;
  final SyncOperationStatus status; // pending, synced, failed, conflicted
  final int retryCount;
  final String? lastError;
  final String? conflictData; // Remote version if conflict

  SyncOperation({
    required this.id,
    required this.entityType,
    required this.type,
    required this.localId,
    this.remoteId,
    required this.operationData,
    required this.createdAt,
    this.syncedAt,
    required this.status,
    required this.retryCount,
    this.lastError,
    this.conflictData,
  });
}

enum SyncOperationType { create, update, delete }

/// Request to initiate synchronization
class SyncRequest {
  final SyncRequestType type;
  final QueryMetadata? queryMetadata;
  final List<String>? entityTypes;
  final DateTime timestamp;

  SyncRequest({
    required this.type,
    this.queryMetadata,
    this.entityTypes,
    required this.timestamp,
  });
}

enum SyncRequestType { full, mutationsOnly, refreshOnly, query }

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int operationsCount;
  final int conflictCount;
  final DateTime timestamp;
  final Duration duration;
  final List<String>? syncedEntityTypes;
  final Map<String, dynamic>? metadata;

  SyncResult({
    required this.success,
    required this.message,
    required this.operationsCount,
    this.conflictCount = 0,
    required this.timestamp,
    required this.duration,
    this.syncedEntityTypes,
    this.metadata,
  });
}

/// Conflict resolution details
class ConflictResolution {
  final String operationId;
  final ConflictResolutionStrategy strategy;
  final dynamic resolvedData;
  final DateTime resolvedAt;
  final String? notes;

  ConflictResolution({
    required this.operationId,
    required this.strategy,
    required this.resolvedData,
    required this.resolvedAt,
    this.notes,
  });
}
```

### Progress and Status Models

```dart
/// Represents progress during a sync operation
class SyncProgress {
  final int currentStep;
  final int totalSteps;
  final String currentOperation;
  final int itemsProcessed;
  final int totalItems;
  final double progressPercentage;
  final DateTime startTime;
  final Duration estimatedTimeRemaining;

  SyncProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.currentOperation,
    required this.itemsProcessed,
    required this.totalItems,
    required this.progressPercentage,
    required this.startTime,
    required this.estimatedTimeRemaining,
  });

  factory SyncProgress.initial() {
    return SyncProgress(
      currentStep: 0,
      totalSteps: 0,
      currentOperation: 'Starting...',
      itemsProcessed: 0,
      totalItems: 0,
      progressPercentage: 0.0,
      startTime: DateTime.now(),
      estimatedTimeRemaining: Duration.zero,
    );
  }
}

/// Overall status of the sync engine
class SyncStatus {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingOperationsCount;
  final int conflictCount;
  final SyncEngineState syncEngineState;
  final int queuedRequests;

  SyncStatus({
    required this.isSyncing,
    this.lastSyncTime,
    required this.pendingOperationsCount,
    required this.conflictCount,
    required this.syncEngineState,
    required this.queuedRequests,
  });
}

/// Detailed refresh status for an entity
class RefreshStatus {
  final String entityType;
  final DateTime? lastRefreshTime;
  final DateTime? nextScheduledRefresh;
  final bool isStale;
  final bool isRefreshing;
  final String? lastError;
  final int refreshCount;

  RefreshStatus({
    required this.entityType,
    this.lastRefreshTime,
    this.nextScheduledRefresh,
    required this.isStale,
    required this.isRefreshing,
    this.lastError,
    required this.refreshCount,
  });
}
```

### State and Event Models

```dart
enum SyncEngineState {
  idle,
  initializing,
  syncing,
  validatingCache,
  paused,
  error,
  disposed,
}

enum SyncCoordinatorState {
  idle,
  syncing,
  paused,
  error,
}

/// Events emitted by the sync engine
class SyncEngineEvent {
  final SyncEngineEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SyncEngineEvent({
    required this.type,
    required this.timestamp,
    this.metadata,
  });
}

enum SyncEngineEventType {
  initialized,
  syncStarted,
  syncCompleted,
  syncFailed,
  syncRequested,
  periodicSyncEnabled,
  lifecycleSyncEnabled,
  cacheValidated,

```
