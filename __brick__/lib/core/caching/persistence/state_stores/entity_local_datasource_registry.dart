import 'package:{{project_name}}/app/utils/entity_type.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_entity_local_datasource_registry.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/entity_local_datasource.dart';

class EntityLocalDatasourceRegistry implements IEntityLocalDatasourceRegistry {
  final Map<EntityType, EntityLocalDatasource> _datasources;

  EntityLocalDatasourceRegistry(Iterable<EntityLocalDatasource> datasources)
    : _datasources = {
        for (final datasource in datasources) datasource.entityType: datasource,
      };

  @override
  EntityLocalDatasource get(EntityType entityType) {
    final datasources = _datasources[entityType];

    if (datasources == null) {
      throw StateError('No EntityLocalDatasource registred for $entityType');
    }
    return datasources;
  }

  /// Throws StateError
  @override
  void register(EntityLocalDatasource datasources) {
    if (_datasources.containsKey(datasources.entityType)) {
      throw StateError(
        "Local datasource already registred for $datasources.entityType",
      );
    }

    _datasources[datasources.entityType] = datasources;
  }
}
