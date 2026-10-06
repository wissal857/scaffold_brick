import 'package:{{project_name}}/app/utils/entity_type.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/entity_local_datasource.dart';

abstract interface class IEntityLocalDatasourceRegistry {
  EntityLocalDatasource get(EntityType entityType);
  void register(EntityLocalDatasource handler);
}
