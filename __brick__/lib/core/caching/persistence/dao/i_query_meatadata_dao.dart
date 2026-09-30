import 'package:{{project_name}}/core/database/app_db.dart';

abstract interface class IQueryMeatadataDao {
  Future<QueryMetadataData?> getQueryMetadata(String queryKey);
  Future<void> upsertQueryMetadata(QueryMetadataCompanion data);
}
