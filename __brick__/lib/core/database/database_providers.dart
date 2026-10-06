import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider.autoDispose<AppDatabase>((ref) {
  return AppDatabase();
});
