import 'package:{{project_name}}/core/database/app_db.dart';

/// Manages the mutations queue and pushes them to the server
/// when network is available or one of the programmed triggers awakes.
abstract interface class IMutationSynchronizer {
  void enqueue(MutationData request);

  /// Processes the elements in the queue and sends them
  /// over the network by batch
  Future<void> synchronize();
}
