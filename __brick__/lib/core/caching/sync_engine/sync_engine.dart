import 'dart:async';

import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';
import 'package:{{project_name}}/core/utils/result.dart';

import 'i_sync_coordinator.dart';
import 'i_sync_engine.dart';

/// Owns lifecycle and concurrency concerns
class SyncEngine implements ISyncEngine {
  SyncEngine({
    required ISyncCoordinator syncCoordinator,
    Duration? schedulerInterval,
    StreamController<SyncStatus>? statusController,
  }) : _syncCoordinator = syncCoordinator,
       _schedulerInterval = schedulerInterval ?? const Duration(minutes: 1),
       _status = SyncStatus.stopped,
       _statusController =
           statusController ?? StreamController<SyncStatus>.broadcast();

  final ISyncCoordinator _syncCoordinator;
  final Duration _schedulerInterval;
  final StreamController<SyncStatus> _statusController;
  SyncStatus _status;
  Timer? _syncTimer;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus get status => _status;
  @override
  bool get isRunning =>
      _status != SyncStatus.stopped && _status != SyncStatus.paused;

  @override
  Future<void> start() async {
    if (isRunning) return;

    _status = SyncStatus.ready;
    _statusController.add(_status);

    // Create periodic timer that calls sync on each tick
    _syncTimer = Timer.periodic(_schedulerInterval, (_) async {
      try {
        await reconcile();
        _status = SyncStatus.synced;
        _statusController.add(_status);
      } catch (e) {
        _status = SyncStatus.failed;
        _statusController.add(_status);
      }
    });
  }

  @override
  Future<void> pause() async {
    if (!isRunning) return;

    _syncTimer?.cancel();
    _syncTimer = null;
    _status = SyncStatus.paused;
    _statusController.add(_status);
  }

  @override
  Future<void> resume() async {
    if (_status != SyncStatus.paused) return;
    await start();
  }

  @override
  Future<void> stop() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _status = SyncStatus.stopped;
    _statusController.add(_status);
  }

  @override
  void enqueueMutation(MutationData mutation) {
    return _syncCoordinator.enqueueMutation(mutation);
  }

  /// 1. check if the engine is running
  /// 2. check if there is an in fligth reconcile
  /// 3. forward call to the sync coordinator
  ///
  /// Throws CachingException.syncAlreadyRunning, CachingException.engineOffline
  @override
  Future<void> reconcile({SyncStrategy strategy = SyncStrategy.full}) async {
    if (!isRunning) throw CachingException.engineOffline();
    // coalesce concurrent sync requests
    if (_status == SyncStatus.syncing) {
      throw CachingException.syncAlreadyRunning();
    }

    _status = SyncStatus.syncing;
    try {
      await _syncCoordinator.coordinateSync();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Result<void>> requestEntityRefresh({
    required String entityType,
    required String id,
  }) {
    // TODO: implement requestEntityRefresh
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> requestQueryRefresh({required String queryKey}) {
    // TODO: implement requestQueryRefresh
    throw UnimplementedError();
  }
}
