import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';

class MutationTypeConverter extends TypeConverter<MutationType, String> {
  // this class is responsible for turning a custom object into a string.
  // this is easy here, but more complex objects could be serialized using
  // json or any other method of your choice.
  const MutationTypeConverter();

  @override
  MutationType fromSql(String fromDb) {
    return MutationType.values.byName(fromDb);
  }

  @override
  String toSql(MutationType value) {
    return value.label;
  }
}
