import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_mutation_queue.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/remote_mutation_executor.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/remote_mutation_result_handler.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/logging/app_logger.dart';

import 'i_mutation_synchronizer.dart';

class MutationSynchronizer implements IMutationSynchronizer {
  MutationSynchronizer({
    //    required SyncOperationDao syncOperationDao,
    required IMutationQueue queue,
    required RemoteMutationExecutor executor,
    required RemoteMutationResultHandler responseHandler,
  }) : _mutationsQueue = queue,
       _remoteMutationExecutor = executor,
       _remoteMutationResultHandler = responseHandler;

  final IMutationQueue _mutationsQueue;
  final RemoteMutationExecutor _remoteMutationExecutor;
  final RemoteMutationResultHandler _remoteMutationResultHandler;
  final _log = AppLogger.logger;

  @override
  void enqueue(MutationData mutation) {
    _log.info("Processing enqueue request : $mutation");
    return _mutationsQueue.enqueue(mutation);
  }

  @override
  Future<void> synchronize() async {
    // Process pending operations by batch
    while (_mutationsQueue.isNotEmpty) {
      final batch = _mutationsQueue.takeBatch();
      if (batch.isEmpty) return;
      final results = await _remoteMutationExecutor.execute(batch);
      await _remoteMutationResultHandler.handle(results);
    }
  }

  // Future<Result<int>> _enqueueDelete(SyncDeleteRequest request) async {
  //   // If the last operation with the same type that acted on the same entity
  //   // has a status different from CANCELLED or FAILED_FATAL do not save.
  //   final duplicateMutation = await _syncOperationDao
  //       .findByEntityTypeAndEntityIdAndMutationType(
  //         request.entityType,
  //         request.entityId,
  //         request.mutationType,
  //       );
  //   if (duplicateMutation.isEmpty) {
  //     try {
  //       final savedOperation = await _saveMutation(request);
  //       return Result.success(value: savedOperation.id);
  //     } catch (e) {
  //       return Result.error(err: e);
  //     }
  //   } else {
  //     // check the status of the last one stored
  //     duplicateMutation.sort((d1, d2) => d1.createdAt.compareTo(d2.createdAt));
  //     final lastDuplicateStatus = duplicateMutation.last.status;
  //     if (lastDuplicateStatus != MutationStatus.failedFatal.label ||
  //         lastDuplicateStatus != MutationStatus.cancelled.label) {
  //       return Result.error(err: OperationQueuedOrCompletedException());
  //     } else {
  //       try {
  //         final savedOperation = await _saveMutation(request);
  //         return Result.success(value: savedOperation.id);
  //       } catch (e) {
  //         return Result.error(err: e);
  //       }
  //     }
  //   }
  // }

  // // Coalesce update to same fields
  // // same as find all other update operations for the same entity
  // // and compare the fields in the two payloads, if they are the same
  // // coalsce otherwise just save.
  // Future<Result<int>> _enqueueUpdate(SyncUpdateRequest request) async {
  //   final duplicateMutation = await _syncOperationDao
  //       .findByEntityTypeAndEntityIdAndMutationType(
  //         request.entityType,
  //         request.entityId,
  //         request.mutationType,
  //       );
  //   if (duplicateMutation.isEmpty) {
  //     try {
  //       final savedOperation = await _saveMutation(request);
  //       return Result.success(value: savedOperation.id);
  //     } catch (e) {
  //       return Result.error(err: e);
  //     }
  //   } else {
  //     // Get the list of pending updates with the same dirty fields
  //     // as the incoming request
  //     final pendingWithIdenticalDirtyFields = duplicateMutation
  //         .where((m) => m.status == MutationStatus.pending.label)
  //         .where((p) => p.matchDirtyFields(request))
  //         .toList();
  //     // Coalsce incoming request with pending operations
  //     try {
  //       final savedOperation = await _syncOperationDao.coalsceUpdates(
  //         pendingWithIdenticalDirtyFields,
  //         request.toInsertCompanion(),
  //       );
  //       // Colesce in the mutation queue
  //       _mutationsQueue.coalesceUpdates(
  //         pendingWithIdenticalDirtyFields.map((p) => p.id).toList(),
  //         savedOperation,
  //       );
  //       return Result.success(value: savedOperation.id);
  //     } catch (e) {
  //       return Result.error(err: e);
  //     }
  //   }
  // }
}
