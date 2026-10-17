import 'package:{{project_name}}/app/utils/entity_type.dart';
import 'package:{{project_name}}/core/caching/network/entity_remote_datasource.dart';

abstract interface class IEntityRemoteDatasourceRegistry {
  EntityRemoteDatasource<dynamic, dynamic> get(EntityType entityType);
  void register(EntityRemoteDatasource<dynamic, dynamic> handler);
}
