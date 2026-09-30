import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/mutation_dirty_fields_converter.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/mutation_type_converter.dart';
import 'package:{{project_name}}/core/caching/persistence/converters/sync_request_payload_converter.dart';
import 'package:{{project_name}}/core/caching/persistence/models/mutations.dart';
import 'package:{{project_name}}/core/caching/persistence/models/query_metadata.dart';
import 'package:{{project_name}}/core/caching/persistence/models/scope_metadata.dart';
import 'package:{{project_name}}/core/constants/app_constants.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [ScopeMetadata, QueryMetadata, Mutations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  final _log = Logger('AppDatabase');

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'db_example',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        _log.finest("Creating the tables");
        await m.createAll();
        await _seedFromJson();
      },
      //onUpgrade: _schemaUpgrade,
    );
  }

  Future<void> _seedFromJson() async {
    _log.finest("Seeding initial data");
    // load the json file from assets
    final String response = await rootBundle.loadString(
      AppConstants.kInitialDataPath,
    );
    final data = json.decode(response) as Map<String, dynamic>;

    // load the db inside a batch
    await batch((batch) async {
      // TODO: load your data here
      _log.info("Database seeded from JSON successfully");
    });
  }
}

extension Migrations on GeneratedDatabase {
  // OnUpgrade get _schemaUpgrade {
  //   final log = Logger('Migrations');
  //   return stepByStep(
  //     from1To2: (m, schema) async {
  //       log.finest("Upgrading the database from 1 to 2");
  //       await m.addColumn(schema.tEmployee, schema.tEmployee.idempotencyKey);
  //     },
  //   );
  // }
}
