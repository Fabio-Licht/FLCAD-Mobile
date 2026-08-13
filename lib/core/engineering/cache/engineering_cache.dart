class EngineeringCacheEntry<T> {
  const EngineeringCacheEntry(this.value, this.createdAt, this.expiresAt);
  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  bool get expired => expiresAt?.isBefore(DateTime.now()) ?? false;
}

class EngineeringCache {
  final Map<String, EngineeringCacheEntry<dynamic>> _values = {};
  int hits = 0, misses = 0;
  String _key(String namespace, String key) => '$namespace::$key';
  T? get<T>(String namespace, String key) {
    final value = _values[_key(namespace, key)];
    if (value == null || value.expired) {
      misses++;
      if (value?.expired ?? false) _values.remove(_key(namespace, key));
      return null;
    }
    hits++;
    return value.value as T;
  }

  void put<T>(String namespace, String key, T value, {Duration? ttl}) {
    final now = DateTime.now();
    _values[_key(namespace, key)] = EngineeringCacheEntry<T>(
      value,
      now,
      ttl == null ? null : now.add(ttl),
    );
  }

  void invalidateNamespace(String namespace) =>
      _values.removeWhere((key, _) => key.startsWith('$namespace::'));
  void clear() => _values.clear();
  double get hitRate => hits + misses == 0 ? 0 : hits / (hits + misses);
  int get length => _values.length;
}
