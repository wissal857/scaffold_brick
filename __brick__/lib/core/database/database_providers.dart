import 'package:{{project_name}}/core/database/app_db.dart';

final appDatabaseProvider = Provider.autoDispose<AppDatabase>((ref) {
  return AppDatabase();
});
