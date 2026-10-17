import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name}}/core/caching/network/entity_remote_datasource_registry.dart';
import 'package:{{project_name}}/core/caching/network/i_entity_remote_datasource_registry.dart';

final entityRemoteDatasourceRegistryProvider =
    Provider<IEntityRemoteDatasourceRegistry>((ref) {
      return EntityRemoteDatasourceRegistry([]);
    });
