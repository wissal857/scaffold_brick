abstract interface class IRefreshSynchronizer {
  Future<void> refreshQuery(String queryKey);
  Future<void> refreshEntity(int id);
}
