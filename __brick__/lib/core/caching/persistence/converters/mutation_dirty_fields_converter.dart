import 'package:drift/drift.dart';

class MutationDirtyFieldsConverter extends TypeConverter<Set<String>, String> {
  // this class is responsible for turning a custom object into a string.
  // this is easy here, but more complex objects could be serialized using
  // json or any other method of your choice.
  const MutationDirtyFieldsConverter();

  @override
  Set<String> fromSql(String fromDb) {
    return fromDb
        .substring(1, fromDb!.length - 1)
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  @override
  String toSql(Set<String> value) {
    return value.toString();
  }
}
