import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';

class SyncPayloadConverter
    extends TypeConverter<SyncMutationRequestPayload, String> {
  // this class is responsible for turning a custom object into a string.
  // this is easy here, but more complex objects could be serialized using
  // json or any other method of your choice.
  const SyncPayloadConverter();

  @override
  SyncMutationRequestPayload fromSql(String fromDb) {
    return SyncMutationRequestPayload.fromString(fromDb);
  }

  @override
  String toSql(SyncMutationRequestPayload value) {
    return value.toString();
  }
}
