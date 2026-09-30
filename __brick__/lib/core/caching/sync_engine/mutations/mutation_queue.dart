import 'dart:collection';
import 'dart:math';

import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_mutation_queue.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/constants/app_constants.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';

class MutationQueue implements IMutationQueue {
  MutationQueue()
    : _mutations = Queue<MutationData>(),
      _capacity = AppConstants.kMutationQueueCapacity;
  final Queue<MutationData> _mutations;
  final int _capacity;

  @override
  bool get isEmpty => _mutations.isEmpty;
  @override
  bool get isNotEmpty => _mutations.isNotEmpty;
  @override
  int get length => _mutations.length;
  @override
  bool get isFull => length == _capacity;

  /// Throws CachingException.mutationQueueCapacityExceeded
  @override
  void enqueue(MutationData syncRequest) {
    if (isFull) throw CachingException.mutationQueueCapacityExceeded();
    _mutations.add(syncRequest);
  }

  @override
  List<MutationData> takeBatch({int size = 10}) {
    int count = min(size, _mutations.length);
    return List.generate(count, (_) => _mutations.removeFirst());
  }

  @override
  void remove(int id) {
    _mutations.removeWhere((m) => m.id == id);
  }

  @override
  void coalesceUpdates(List<int> toDelete, MutationData newOperation) {
    toDelete.forEach(remove);
    enqueue(newOperation);
  }

  @override
  void setStatus(int id, MutationStatus newStatus) {
    _mutations
        .where((m) => m.id == id)
        .map((m) => m.copyWith(status: newStatus.label));
  }

  @override
  void clear() {
    _mutations.clear();
  }
}
