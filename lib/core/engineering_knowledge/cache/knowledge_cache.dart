class KnowledgeCache {
  final Map<String, Object> _values = {};
  int hits = 0, misses = 0;
  T? get<T>(String key) {
    final value = _values[key];
    if (value == null) {
      misses++;
      return null;
    }
    hits++;
    return value as T;
  }

  void put<T extends Object>(String key, T value) => _values[key] = value;
  void clear() => _values.clear();
}
