import 'package:{{project_name}}/core/utils/paginated_query_params.dart';
import 'i_db_query_strategy.dart';

abstract interface class IDbQueryStrategyFactory {
  IDbQueryStrategy? getStrategy(PaginatedQueryParams params);
}
