part of 'package:{{project_name}}/core/errors/app_exception.dart';

enum CachingExceptionType {
  syncAlreadyRunning,
  engineOffline,
  operationQueuedOrCompleted,
  mutationQueueCapacityExceeded,
  dequeuingEmptyQueue,
  previousPayloadMissing,
}

sealed class CachingException extends AppException {
  const CachingException._({required super.code, required super.message});

  const factory CachingException.syncAlreadyRunning() = SyncAlreadyRunning._;
  const factory CachingException.engineOffline() = EngineOffline._;
  const factory CachingException.operationQueuedOrCompleted() =
      OperationQueuedOrCompleted._;
  const factory CachingException.mutationQueueCapacityExceeded() =
      MutationQueueCapacityExceeded._;
  const factory CachingException.dequeuingEmptyQueue() = DequeuingEmptyQueue._;
  const factory CachingException.previousPayloadMissingOrCorrupted() =
      PreviousPayloadMissingOrCorrupted._;
  const factory CachingException.duplicateInsertOfMutation() =
      DuplicateInsertOfMutation._;
  const factory CachingException.corruptedMutationTable({
    required String message,
  }) = CorruptedMutationTable._;
}

final class SyncAlreadyRunning extends CachingException {
  const SyncAlreadyRunning._()
    : super._(
        code: 'SYNC_ALREADY_RUNNING',
        message:
            "Sync was skipped due to a previous sync call that is still running.",
      );
}

final class EngineOffline extends CachingException {
  const EngineOffline._()
    : super._(
        code: 'ENGINE_OFFLINE',
        message:
            "Sync was skipped due to the offline status of the sync engine.",
      );
}

final class OperationQueuedOrCompleted extends CachingException {
  const OperationQueuedOrCompleted._()
    : super._(
        code: 'OPERATION_ALREADY_QUEUED_OR_COMPLETED',
        message:
            "A same instance of the sync request is already queued or completed.",
      );
}

final class MutationQueueCapacityExceeded extends CachingException {
  const MutationQueueCapacityExceeded._()
    : super._(
        code: 'SYNC_QUEUE_CAPACITY_EXCEEDED',
        message: 'In memory sync queue capacity exceeded.',
      );
}

final class DequeuingEmptyQueue extends CachingException {
  const DequeuingEmptyQueue._()
    : super._(
        code: 'DEQUEING_EMPTY_QUEUE',
        message: 'Cannot dequeue an empty queue.',
      );
}

final class PreviousPayloadMissingOrCorrupted extends CachingException {
  const PreviousPayloadMissingOrCorrupted._()
    : super._(
        code: 'PREVIOUS_PAYLOAD_MISSING',
        message: 'Previous payload is missing from the recorded mutation.',
      );
}

final class DuplicateInsertOfMutation extends CachingException {
  const DuplicateInsertOfMutation._()
    : super._(
        code: 'DUPLICATE_MUTATION_INSERT',
        message: 'There is a previous identical mutation queued.',
      );
}

final class CorruptedMutationTable extends CachingException {
  const CorruptedMutationTable._({required super.message})
    : super._(code: 'CORRUPTED_MUTATION_TABLE');
}
