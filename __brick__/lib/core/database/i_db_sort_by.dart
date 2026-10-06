import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

abstract interface class IDbSortBy<T extends Table> {
  String get label;
  bool get isDefault;

  List<OrderingTerm Function(T)> toOrderingTerms(
    AppDatabase db,
    bool ascending,
  );
}
