import 'package:drift/drift.dart';
import 'package:{{project_name}}/app/utils/entity_type.dart';

class EntityTypeConverter extends TypeConverter<EntityType, String> {
  // this class is responsible for turning a custom object into a string.
  // this is easy here, but more complex objects could be serialized using
  // json or any other method of your choice.
  const EntityTypeConverter();

  @override
  EntityType fromSql(String fromDb) {
    return EntityType.values.byName(fromDb);
  }

  @override
  String toSql(EntityType value) {
    return value.label;
  }
}
