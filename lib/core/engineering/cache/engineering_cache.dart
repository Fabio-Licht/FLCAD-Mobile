class EngineeringCacheNamespaces {
  static const geometry = 'geometry',
      reference = 'reference',
      regions = 'regions',
      surface = 'surface',
      sketch = 'sketch',
      topology = 'topology',
      reconstruction = 'reconstruction',
      ai = 'ai',
      knowledge = 'knowledge',
      cognition = 'cognition',
      project = 'project';
}

class EngineeringCacheEntry<T> {
  const EngineeringCacheEntry(
    this.value,
    this.createdAt,
    this.expiresAt, {
    this.fingerprint,
    this.version = 1,
  });
  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? fingerprint;
  final int version;
  bool get expired => expiresAt?.isBefore(DateTime.now()) ?? false;
}

class EngineeringCacheStatistics {
  const EngineeringCacheStatistics(
    this.entries,
    this.hits,
    this.misses,
    this.evictions,
  );
  final int entries, hits, misses, evictions;
  double get hitRate => hits + misses == 0 ? 0 : hits / (hits + misses);
}

class EngineeringCache {
  final Map<String, EngineeringCacheEntry<dynamic>> _values = {};
  int hits = 0, misses = 0, _evictions = 0;
  String _key(String namespace, String key) => '$namespace::$key';

  T? get<T>(String namespace, String key, {String? fingerprint, int? version}) {
    final cacheKey = _key(namespace, key), value = _values[cacheKey];
    final invalid =
        value == null ||
        value.expired ||
        (fingerprint != null && value.fingerprint != fingerprint) ||
        (version != null && value.version != version);
    if (invalid) {
      misses++;
      if (value != null) {
        _values.remove(cacheKey);
        _evictions++;
      }
      return null;
    }
    hits++;
    return value.value as T;
  }

  void put<T>(
    String namespace,
    String key,
    T value, {
    Duration? ttl,
    String? fingerprint,
    int version = 1,
  }) {
    final now = DateTime.now();
    _values[_key(namespace, key)] = EngineeringCacheEntry<T>(
      value,
      now,
      ttl == null ? null : now.add(ttl),
      fingerprint: fingerprint,
      version: version,
    );
  }

  int cleanupExpired() {
    final before = _values.length;
    _values.removeWhere((_, value) => value.expired);
    final removed = before - _values.length;
    _evictions += removed;
    return removed;
  }

  void invalidateNamespace(String namespace) {
    final before = _values.length;
    _values.removeWhere((key, _) => key.startsWith('$namespace::'));
    _evictions += before - _values.length;
  }

  void invalidateFingerprint(String fingerprint) {
    final before = _values.length;
    _values.removeWhere((_, value) => value.fingerprint == fingerprint);
    _evictions += before - _values.length;
  }

  void clear() {
    _evictions += _values.length;
    _values.clear();
  }

  double get hitRate => statistics.hitRate;
  int get length => _values.length;
  EngineeringCacheStatistics get statistics =>
      EngineeringCacheStatistics(length, hits, misses, _evictions);
}
