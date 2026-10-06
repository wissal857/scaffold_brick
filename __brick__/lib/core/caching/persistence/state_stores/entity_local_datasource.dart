import 'package:{{project_name}}/app/utils/entity_type.dart';

abstract interface class EntityLocalDatasource {
  EntityType get entityType;

  Future<Map<String, dynamic>?> get(int entityId);

  Future<int> save(Map<String, dynamic> state);

  // partial update: ignore absent fields
  Future<void> update(int entityId, Map<String, dynamic> state);

  Future<void> delete(int entityId);

  Future<void> resetTombstone(int entityId, String syncStatus);

  Future<void> restore(int entityId, Map<String, dynamic> snapshot);
}
