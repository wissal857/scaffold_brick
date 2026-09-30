abstract interface class StateHandler {
  String get entityType;

  Future<Map<String, dynamic>?> get(String entityId);

  Future<int> save(Map<String, dynamic> state);

  // partial update: ignore absent fields
  Future<void> update(String entityId, Map<String, dynamic> state);

  Future<void> delete(String entityId);

  Future<void> resetTombstone(String entityId, String syncStatus);

  Future<void> restore(String entityId, Map<String, dynamic> snapshot);
}
