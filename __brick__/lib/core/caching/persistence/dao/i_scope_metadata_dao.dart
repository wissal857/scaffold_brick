import 'package:{{project_name}}/core/database/app_db.dart';

abstract interface class IScopeMetadataDao {
  // Scope metadata operations
  Future<void> insertScopeMetadata(ScopeMetadataCompanion data);
  Future<List<ScopeMetadataData>> getPendingOperations();
  Future<void> updateSyncStatus(int id, String status, {String? errorMessage});
  Future<void> incrementRetryCount(int id);
}
