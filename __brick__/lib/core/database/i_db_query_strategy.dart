import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/database/db_paginated_query_params.dart';

abstract interface class IDbQueryStrategy<
  T extends Table,
  D extends DataClass
> {
  Expression<bool> buildWhereClause(DbPaginatedQueryParams<D> params, T table);
}
