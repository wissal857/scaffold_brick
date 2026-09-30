```dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
```

### RetryPolicy

```dart
enum BackoffStrategy {
  fixed,
  linear,
  exponential,
}

class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final BackoffStrategy backoffStrategy;
  final Duration timeout;
  final bool useJitter;

  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 1),
    this.backoffStrategy = BackoffStrategy.exponential,
    this.timeout = const Duration(seconds: 30),
    this.useJitter = true,
  });

  bool shouldRetry(
    SyncOperation operation,
    Exception error,
  ) {
    if (operation.retryCount >= maxRetries) {
      return false;
    }

    if (error is TimeoutException || error is SocketException) {
      return true;
    }

    if (error is HttpException) {
      return _isRetryableHttpError(error);
    }

    // Some API clients expose HTTP failures as generic exceptions.
    final message = error.toString().toLowerCase();

    return message.contains('timeout') ||
        message.contains('connection reset') ||
        message.contains('connection closed') ||
        message.contains('network is unreachable') ||
        message.contains('429') ||
        message.contains('408') ||
        message.contains('425') ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504');
  }

  bool _isRetryableHttpError(HttpException error) {
    final message = error.message;

    return message.contains('408') ||
        message.contains('425') ||
        message.contains('429') ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504');
  }

  Duration getNextDelay(SyncOperation operation) {
    final retryCount = operation.retryCount;

    final double delayMilliseconds;

    switch (backoffStrategy) {
      case BackoffStrategy.fixed:
        delayMilliseconds = initialDelay.inMilliseconds.toDouble();

      case BackoffStrategy.linear:
        delayMilliseconds =
            initialDelay.inMilliseconds * (retryCount + 1).toDouble();

      case BackoffStrategy.exponential:
        delayMilliseconds = initialDelay.inMilliseconds *
            math.pow(2, retryCount).toDouble();
    }

    var delay = Duration(
      milliseconds: math.min(
        delayMilliseconds.round(),
        maxDelay.inMilliseconds,
      ),
    );

    if (useJitter && delay.inMilliseconds > 0) {
      // Full jitter: random delay between zero and the calculated delay.
      final jitterMilliseconds = math.Random().nextInt(
        delay.inMilliseconds + 1,
      );

      delay = Duration(milliseconds: jitterMilliseconds);
    }

    return delay;
  }

  Future<T> execute<T>(
    Future<T> Function() operation, {
    required SyncOperation syncOperation,
    void Function(int attempt, Duration delay)? onRetry,
  }) async {
    var currentOperation = syncOperation;
    Exception? lastError;

    while (true) {
      try {
        return await operation().timeout(timeout);
      } on Exception catch (error) {
        lastError = error;

        if (!shouldRetry(currentOperation, error)) {
          rethrow;
        }

        final delay = getNextDelay(currentOperation);
        final nextRetryCount = currentOperation.retryCount + 1;

        onRetry?.call(nextRetryCount, delay);

        await Future.delayed(delay);

        currentOperation = currentOperation.copyWith(
          retryCount: nextRetryCount,
          updatedAt: DateTime.now(),
        );
      }
    }
  }
}
```

Update `SyncMutationSynchronizerImpl.processPendingOperations()` so that the retry count is incremented before re-enqueuing the operation:

```dart
@override
Future<void> processPendingOperations() async {
  while (true) {
    final operation = await _operationQueue.dequeue();

    if (operation == null) {
      break;
    }

    try {
      final response = await _apiClient
          .sendMutation(operation)
          .timeout(_retryPolicy.timeout);

      if (response.success) {
        await _operationQueue.markSucceeded(operation.id);
        continue;
      }

      if (response.isConflict && response.data != null) {
        final resolvedData = await _conflictResolver.resolve(
          localData: operation.data,
          remoteData: response.data!,
          strategy: ConflictStrategy.serverPreferred,
        );

        final updatedOperation = operation.copyWith(
          data: resolvedData,
          retryCount: 0,
          updatedAt: DateTime.now(),
        );

        await _operationQueue.updateOperation(
          operation.id,
          updatedOperation.data,
        );

        await _operationQueue.enqueue(updatedOperation);
        continue;
      }

      await _operationQueue.markFailed(
        operation.id,
        'Mutation failed without a retryable error',
      );
    } on Exception catch (error) {
      if (_retryPolicy.shouldRetry(operation, error)) {
        final nextRetryCount = operation.retryCount + 1;
        final delay = _retryPolicy.getNextDelay(operation);

        final retryOperation = operation.copyWith(
          retryCount: nextRetryCount,
          status: OperationStatus.pending,
          updatedAt: DateTime.now(),
          error: error.toString(),
        );

        await Future.delayed(delay);
        await _operationQueue.enqueue(retryOperation);
      } else {
        await _operationQueue.markFailed(
          operation.id,
          error.toString(),
        );
      }
    }
  }
}
```

> `SyncOperation.copyWith()` should support at least `data`, `retryCount`, `status`, `error`, and `updatedAt`.

---

### ConflictResolver

```dart
enum ConflictStrategy {
  lastWriteWins,
  serverPreferred,
  clientPreferred,
  merge,
}

class ConflictResolver {
  final DataMerger _dataMerger;

  const ConflictResolver({
    required DataMerger dataMerger,
  }) : _dataMerger = dataMerger;

  Future<SyncData> resolve({
    required SyncData localData,
    required SyncData remoteData,
    required ConflictStrategy strategy,
  }) async {
    switch (strategy) {
      case ConflictStrategy.serverPreferred:
        return remoteData;

      case ConflictStrategy.clientPreferred:
        return localData;

      case ConflictStrategy.lastWriteWins:
        return _resolveLastWriteWins(
          localData,
          remoteData,
        );

      case ConflictStrategy.merge:
        return _mergeData(
          localData,
          remoteData,
        );
    }
  }

  SyncData _resolveLastWriteWins(
    SyncData localData,
    SyncData remoteData,
  ) {
    final localUpdatedAt = localData.updatedAt;
    final remoteUpdatedAt = remoteData.updatedAt;

    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      return remoteData;
    }

    if (localUpdatedAt == null) {
      return remoteData;
    }

    if (remoteUpdatedAt == null) {
      return localData;
    }

    return localUpdatedAt.isAfter(remoteUpdatedAt)
        ? localData
        : remoteData;
  }

  Future<SyncData> _mergeData(
    SyncData localData,
    SyncData remoteData,
  ) async {
    final mergedValue = await _dataMerger.merge(
      localData.value,
      remoteData.value,
    );

    return remoteData.copyWith(
      value: mergedValue,
      updatedAt: DateTime.now(),
    );
  }
}
```

A generic merger interface keeps the conflict resolver independent of the actual data model:

```dart
abstract class DataMerger {
  Future<Object?> merge(
    Object? localValue,
    Object? remoteValue,
  );
}

class MapDataMerger implements DataMerger {
  const MapDataMerger();

  @override
  Future<Object?> merge(
    Object? localValue,
    Object? remoteValue,
  ) async {
    if (localValue is! Map || remoteValue is! Map) {
      // For scalar values, server data is the safest default.
      return remoteValue;
    }

    final merged = <Object?, Object?>{};

    merged.addAll(remoteValue);
    merged.addAll(localValue);

    return merged;
  }
}
```

Example `SyncData` model:

```dart
class SyncData {
  final String id;
  final Object? value;
  final DateTime? updatedAt;
  final int version;

  const SyncData({
    required this.id,
    required this.value,
    this.updatedAt,
    this.version = 0,
  });

  SyncData copyWith({
    String? id,
    Object? value,
    DateTime? updatedAt,
    int? version,
  }) {
    return SyncData(
      id: id ?? this.id,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
```

---

### RefreshSynchronizer

```dart
abstract class SyncRefreshSynchronizer {
  Future<void> start();
  Future<void> stop();
  Future<void> performRefresh();
}
```

```dart
class SyncRefreshSynchronizerImpl
    implements SyncRefreshSynchronizer {
  final RefreshPolicy _refreshPolicy;
  final SyncStrategyExecutor _strategyExecutor;
  final CacheValidator _validator;

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  bool _isStarted = false;

  SyncRefreshSynchronizerImpl({
    required RefreshPolicy refreshPolicy,
    required SyncStrategyExecutor strategyExecutor,
    required CacheValidator validator,
  })  : _refreshPolicy = refreshPolicy,
        _strategyExecutor = strategyExecutor,
        _validator = validator;

  @override
  Future<void> start() async {
    if (_isStarted) {
      return;
    }

    _isStarted = true;

    if (_refreshPolicy.refreshInterval != null) {
      _refreshTimer = Timer.periodic(
        _refreshPolicy.refreshInterval!,
        (_) async {
          try {
            await performRefresh();
          } catch (_) {
            // Periodic refresh failures should not terminate the timer.
            // They can be exposed through a logger or status stream.
          }
        },
      );
    }
  }

  @override
  Future<void> stop() async {
    _isStarted = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  Future<void> performRefresh() async {
    if (!_isStarted && _refreshPolicy.requireStarted) {
      throw StateError('Refresh synchronizer has not been started');
    }

    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    try {
      final shouldRefresh = await _refreshPolicy.shouldRefresh();

      if (!shouldRefresh) {
        return;
      }

      final strategy = await _refreshPolicy.selectStrategy();

      await _strategyExecutor.execute(strategy);

      final cacheIsValid = await _validator.validateCache();

      if (!cacheIsValid) {
        throw CacheValidationException(
          'Cache validation failed after refresh',
        );
      }

      await _refreshPolicy.markRefreshCompleted();
    } finally {
      _isRefreshing = false;
    }
  }
}
```

### RefreshPolicy

```dart
class RefreshPolicy {
  final Duration? refreshInterval;
  final bool requireStarted;
  final bool refreshWhenCacheIsInvalid;
  final SyncStrategy Function()? strategySelector;

  DateTime? _lastRefresh;

  RefreshPolicy({
    this.refreshInterval = const Duration(minutes: 5),
    this.requireStarted = false,
    this.refreshWhenCacheIsInvalid = true,
    this.strategySelector,
  });

  Future<bool> shouldRefresh() async {
    if (_lastRefresh == null) {
      return true;
    }

    if (refreshInterval == null) {
      return true;
    }

    return DateTime.now().difference(_lastRefresh!) >=
        refreshInterval!;
  }

  Future<SyncStrategy> selectStrategy() async {
    if (strategySelector != null) {
      return strategySelector!();
    }

    // Incremental synchronization is normally preferable after the
    // first successful full synchronization.
    return _lastRefresh == null
        ? SyncStrategy.full
        : SyncStrategy.delta;
  }

  Future<void> markRefreshCompleted() async {
    _lastRefresh = DateTime.now();
  }

  void reset() {
    _lastRefresh = null;
  }
}
```

### Sync strategy executor

```dart
enum SyncStrategy {
  full,
  delta,
}

abstract class SyncStrategyExecutor {
  Future<void> execute(SyncStrategy strategy);
}
```

```dart
class SyncStrategyExecutorImpl implements SyncStrategyExecutor {
  final FullSyncStrategy _fullSyncStrategy;
  final DeltaSyncStrategy _deltaSyncStrategy;

  const SyncStrategyExecutorImpl({
    required FullSyncStrategy fullSyncStrategy,
    required DeltaSyncStrategy deltaSyncStrategy,
  })  : _fullSyncStrategy = fullSyncStrategy,
        _deltaSyncStrategy = deltaSyncStrategy;

  @override
  Future<void> execute(SyncStrategy strategy) {
    switch (strategy) {
      case SyncStrategy.full:
        return _fullSyncStrategy.execute();

      case SyncStrategy.delta:
        return _deltaSyncStrategy.execute();
    }
  }
}
```

Example strategy contracts:

```dart
abstract class FullSyncStrategy {
  Future<void> execute();
}

abstract class DeltaSyncStrategy {
  Future<void> execute();
}
```

One important correction to the original `stop()` implementation: add the stopped status before closing the stream, because adding an event after `close()` throws a `StateError`.

```dart
@override
Future<void> stop() async {
  await _mutationSync.stop();
  await _refreshSync.stop();
  await _coordinator.dispose();

  if (!_statusController.isClosed) {
    _statusController.add(SyncStatus.stopped);
    await _statusController.close();
  }
}
```

Also, `OperationQueue.dequeue()` should not repeatedly return the same operation after a successful send. A production queue should either remove the item when dequeued or mark it as `inFlight`:

```dart
@override
Future<SyncOperation?> dequeue() async {
  final pending = _box.values
      .where((operation) =>
          operation.status == OperationStatus.pending)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  if (pending.isEmpty) {
    return null;
  }

  final operation = pending.first;

  await _box.put(
    operation.id,
    operation.copyWith(
      status: OperationStatus.inFlight,
      updatedAt: DateTime.now(),
    ),
  );

  return operation;
}
```

Your `OperationStatus` enum should therefore include:

```dart
enum OperationStatus {
  pending,
  inFlight,
  succeeded,
  failed,
}
```

Also, make sure failed retries increment retryCount; otherwise maxRetries will never be reached:

```dart
final retryOperation = operation.copyWith( retryCount: operation.retryCount + 1, status: OperationStatus.pending, updatedAt: DateTime.now(), error: e.toString(),);
await Future.delayed(delay);
await _operationQueue.enqueue(retryOperation);
```
