import 'package:{{project_name}}/app/utils/entity_type.dart';
import 'package:{{project_name}}/core/data/models/remote/api_response_model.dart';
import 'package:{{project_name}}/core/data/models/remote/paginated_api_response.dart';
import 'package:{{project_name}}/core/network/network_paginated_query_params.dart';

abstract interface class EntityRemoteDatasource<Res, Req> {
  EntityType get entityType;

  Future<ApiResponseModel<Res>> add(Req value);
  Future<ApiResponseModel<Res>> fetchById(int id);
  Future<PaginatedApiResponse<Res>> fetchAll(
    NetworkPaginatedQueryParams params,
  );
  Future<ApiResponseModel<Res>> update(int id, Req value);
  Future<ApiResponseModel<Res>> delete(int id);
}
