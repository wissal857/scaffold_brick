abstract interface class PersistenceTransaction {
  Future<T> run<T>(Future<T> Function() action);
}
