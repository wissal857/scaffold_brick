import 'package:{{project_name}}/core/caching/persistence/transactions/persistence_transaction.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

class DriftPersistenceTransaction implements PersistenceTransaction {
  final AppDatabase database;

  const DriftPersistenceTransaction(this.database);

  @override
  Future<T> run<T>(Future<T> Function() action) {
    return database.transaction(action);
  }
}
