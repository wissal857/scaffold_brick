import 'package:{{project_name}}/app/utils/entity_type.dart';
import 'package:{{project_name}}/core/caching/network/entity_remote_datasource.dart';
import 'package:{{project_name}}/core/caching/network/i_entity_remote_datasource_registry.dart';

class EntityRemoteDatasourceRegistry
    implements IEntityRemoteDatasourceRegistry {
  final Map<EntityType, EntityRemoteDatasource<dynamic, dynamic>> _datasources;

  EntityRemoteDatasourceRegistry(
    Iterable<EntityRemoteDatasource<dynamic, dynamic>> datasources,
  ) : _datasources = {
        for (final datasource in datasources) datasource.entityType: datasource,
      };

  @override
  EntityRemoteDatasource<dynamic, dynamic> get(EntityType entityType) {
    final datasources = _datasources[entityType];

    if (datasources == null) {
      throw StateError('No EntityRemoteDatasource registred for $entityType');
    }
    return datasources;
  }

  /// Throws StateError
  @override
  void register(EntityRemoteDatasource<dynamic, dynamic> datasources) {
    if (_datasources.containsKey(datasources.entityType)) {
      throw StateError(
        "Local datasource already registred for $datasources.entityType",
      );
    }

    _datasources[datasources.entityType] = datasources;
  }
}
