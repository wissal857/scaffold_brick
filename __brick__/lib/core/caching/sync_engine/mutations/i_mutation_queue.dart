import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

abstract interface class IMutationQueue {
  void enqueue(MutationData syncRequest);

  /// Replaces the given updates with the new one
  void coalesceUpdates(List<int> toDelete, MutationData newOperation);

  void setStatus(int id, MutationStatus newStatus);

  /// Empties the queue
  void clear();

  void remove(int id);

  List<MutationData> takeBatch({int size = 10});

  bool get isEmpty;
  bool get isNotEmpty;
  int get length;
  bool get isFull;
}
