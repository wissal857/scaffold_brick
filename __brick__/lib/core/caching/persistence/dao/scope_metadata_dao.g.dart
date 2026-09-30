// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scope_metadata_dao.dart';

// ignore_for_file: type=lint
mixin _$ScopeMetadataDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScopeMetadataTable get scopeMetadata => attachedDatabase.scopeMetadata;
  ScopeMetadataDaoManager get managers => ScopeMetadataDaoManager(this);
}

class ScopeMetadataDaoManager {
  final _$ScopeMetadataDaoMixin _db;
  ScopeMetadataDaoManager(this._db);
  $$ScopeMetadataTableTableManager get scopeMetadata =>
      $$ScopeMetadataTableTableManager(_db.attachedDatabase, _db.scopeMetadata);
}
