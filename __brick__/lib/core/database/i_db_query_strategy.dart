import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/utils/paginated_query_params.dart';

abstract interface class IDbQueryStrategy<T> {
  Expression<bool> buildWhereClause(PaginatedQueryParams params, T table);
}
