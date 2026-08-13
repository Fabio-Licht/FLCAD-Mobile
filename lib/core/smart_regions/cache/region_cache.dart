class RegionCache {
  final Map<String, Object> _values = {};
  T? read<T>(String meshFingerprint, String regionDna, String operation) =>
      _values['$meshFingerprint:$regionDna:$operation'] as T?;
  void write(
    String meshFingerprint,
    String regionDna,
    String operation,
    Object value,
  ) => _values['$meshFingerprint:$regionDna:$operation'] = value;
  void invalidateRegion(String regionDna) =>
      _values.removeWhere((key, _) => key.contains(':$regionDna:'));
}
