import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/caching/models/valid_mutation_data.dart';

abstract interface class IMutationQueue {
  void enqueue(ValidMutationData mutationData);

  void setStatus(int id, MutationStatus newStatus);

  /// Empties the queue
  void clear();

  void remove(int id);

  List<ValidMutationData> takeBatch({int size = 10});

  bool get isEmpty;
  bool get isNotEmpty;
  int get length;
  bool get isFull;
}
