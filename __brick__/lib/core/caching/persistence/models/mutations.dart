import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/mutation_dirty_fields_converter.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/mutation_type_converter.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/sync_request_payload_converter.dart';
import 'package:{{project_name}}/core/caching/models/valid_mutation_data.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/entity_type_converter.dart';

/// Represent the mutations that need to be synced with the server
@DataClassName('MutationData')
@TableIndex(name: "idx_mutation_entity_type", columns: {#entityType})
@TableIndex(name: "idx_mutation_entity_local_id", columns: {#entityLocalId})
@TableIndex(name: "idx_mutation_idempotency_key", columns: {#idempotencyKey})
@TableIndex(name: "idx_mutation_status", columns: {#status})
class Mutations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType =>
      text().map(const MutationTypeConverter())(); // CREATE,UPDATE,DELETE
  TextColumn get entityType => text().map(const EntityTypeConverter())();
  IntColumn get entityLocalId => integer()();
  TextColumn get entityRemoteId => text().nullable()();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get etag => text().nullable()();
  TextColumn get payload =>
      text().map(const SyncPayloadConverter()).nullable()(); //Json encoded
  TextColumn get previousPayload =>
      text().map(const SyncPayloadConverter()).nullable()(); //Json encoded
  TextColumn get status => text()();
  TextColumn? get error => text().nullable()();
  //IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn? get dirtyFields =>
      text().map(const MutationDirtyFieldsConverter()).nullable()();
  //DateTimeColumn? get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

extension MutationDataExtension on MutationData {
  /// Returns a valid representation of the data.
  ///
  /// Throws [CachingException.corruptedMutationTable]
  ValidMutationData toValidData() {
    return ValidMutationData.fromData(this);
  }
}
