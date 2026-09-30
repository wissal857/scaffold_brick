// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutation_dao.dart';

// ignore_for_file: type=lint
mixin _$MutationDaoMixin on DatabaseAccessor<AppDatabase> {
  $MutationsTable get mutations => attachedDatabase.mutations;
  MutationDaoManager get managers => MutationDaoManager(this);
}

class MutationDaoManager {
  final _$MutationDaoMixin _db;
  MutationDaoManager(this._db);
  $$MutationsTableTableManager get mutations =>
      $$MutationsTableTableManager(_db.attachedDatabase, _db.mutations);
}
