// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_metadata_dao.dart';

// ignore_for_file: type=lint
mixin _$QueryMetadataDaoMixin on DatabaseAccessor<AppDatabase> {
  $QueryMetadataTable get queryMetadata => attachedDatabase.queryMetadata;
  QueryMetadataDaoManager get managers => QueryMetadataDaoManager(this);
}

class QueryMetadataDaoManager {
  final _$QueryMetadataDaoMixin _db;
  QueryMetadataDaoManager(this._db);
  $$QueryMetadataTableTableManager get queryMetadata =>
      $$QueryMetadataTableTableManager(_db.attachedDatabase, _db.queryMetadata);
}
