import 'package:drift/drift.dart';

import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/sorting/i_sort_by.dart';

abstract interface class IDbSortMapper<S extends ISortBy, T extends Table> {
  List<OrderingTerm Function(T)> mapToOrderingTerm(
    S sortBy,
    AppDatabase db,
    bool ascending,
  );
}
