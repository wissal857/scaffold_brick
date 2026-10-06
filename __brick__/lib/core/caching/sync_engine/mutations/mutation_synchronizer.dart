import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_mutation_queue.dart';
import 'package:{{project_name}}/core/caching/persistence/models/mutations.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_remote_mutation_executor.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/remote_mutation_result_handler.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/logging/app_logger.dart';

import 'i_mutation_synchronizer.dart';

class MutationSynchronizer implements IMutationSynchronizer {
  MutationSynchronizer({
    //    required SyncOperationDao syncOperationDao,
    required IMutationQueue queue,
    required IRemoteMutationExecutor executor,
    required RemoteMutationResultHandler responseHandler,
  }) : _mutationsQueue = queue,
       _remoteMutationExecutor = executor,
       _remoteMutationResultHandler = responseHandler;

  final IMutationQueue _mutationsQueue;
  final IRemoteMutationExecutor _remoteMutationExecutor;
  final RemoteMutationResultHandler _remoteMutationResultHandler;
  final _log = AppLogger.logger;

  @override
  void enqueue(MutationData mutation) {
    _log.info("Processing enqueue request : $mutation");
    return _mutationsQueue.enqueue(mutation.toValidData());
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
}
