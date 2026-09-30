import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/caching/persistence/models/query_metadata.dart';

import 'i_query_meatadata_dao.dart';

part 'query_metadata_dao.g.dart';

@DriftAccessor(tables: [QueryMetadata])
class QueryMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$QueryMetadataDaoMixin
    implements IQueryMeatadataDao {
  // this constructor is required so that the main database can create an instance
  // of this object.
  QueryMetadataDao(super.attachedDatabase);

  @override
  Future<QueryMetadataData?> getQueryMetadata(String queryKey) => (select(
    queryMetadata,
  )..where((t) => t.queryKey.equals(queryKey))).getSingleOrNull();

  @override
  Future<void> upsertQueryMetadata(data) =>
      into(queryMetadata).insert(data, mode: InsertMode.replace);
}
