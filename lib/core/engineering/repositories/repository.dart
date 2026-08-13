abstract interface class Repository<T, Id> {
  Future<T?> findById(Id id);
  Future<List<T>> findAll();
  Future<void> save(T value);
  Future<void> delete(T value);
}

abstract interface class VersionedRepository<T, Id>
    implements Repository<T, Id> {
  Future<List<T>> history(Id id);
}
