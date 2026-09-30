import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/mutation_dirty_fields_converter.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/mutation_type_converter.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/sync_request_payload_converter.dart';

/// Represent the mutations that need to be synced with the server
@DataClassName('MutationData')
@TableIndex(name: "idx_mutation_entity_type", columns: {#entityType})
@TableIndex(name: "idx_mutation_entity_id", columns: {#entityId})
@TableIndex(name: "idx_mutation_idempotency_key", columns: {#idempotencyKey})
@TableIndex(name: "idx_mutation_status", columns: {#status})
class Mutations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType =>
      text().map(const MutationTypeConverter())(); // CREATE,UPDATE,DELETE
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get etag => text()();
  TextColumn get payload =>
      text().map(const SyncPayloadConverter())(); //Json encoded
  TextColumn get previousPayload =>
      text().map(const SyncPayloadConverter()).nullable()(); //Json encoded
  TextColumn get status => text()();
  TextColumn? get error => text().nullable()();
  //IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn? get dirtyFields =>
      text().map(const MutationDirtyFieldsConverter()).nullable()();
  //DateTimeColumn? get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();
}

// extension MutationDataExtension on MutationData {
//   /// Matches the dirty fields with those of [request]
//   ///
//   /// Returns true if all fields are contained in [request.dirtyFields]
//   bool matchDirtyFields(SyncUpdateRequest request) {
//     final log = AppLogger.logger;

//     if (operationType != MutationType.update) {
//       log.warning(
//         "Calling MutationData.matchDirtyFields on an operation type diffrent from update",
//       );
//       return false;
//     }
//     if (dirtyFields == null) return false;

//     return dirtyFields!.length == request.dirtyFields.length &&
//         dirtyFields!.every(request.dirtyFields.contains);
//   }
// }
