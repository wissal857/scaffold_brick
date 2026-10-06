import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

abstract interface class ILocalStateStore {
  /// Saves an entity with the create operation in
  /// a transaction
  Future<MutationData> save({required SyncCreateRequest syncRequest});

  Future<void> delete({required SyncDeleteRequest syncRequest});

  Future<void> update({required SyncUpdateRequest syncRequest});
}
