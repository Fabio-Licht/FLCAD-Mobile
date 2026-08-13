class EngineeringMetric {
  const EngineeringMetric(
    this.name,
    this.value,
    this.unit,
    this.timestamp,
    this.tags,
  );
  final String name, unit;
  final num value;
  final DateTime timestamp;
  final Map<String, String> tags;
}

class EngineeringMetrics {
  final List<EngineeringMetric> _values = [];
  void record(
    String name,
    num value, {
    String unit = 'count',
    Map<String, String> tags = const {},
  }) => _values.add(EngineeringMetric(name, value, unit, DateTime.now(), tags));
  Iterable<EngineeringMetric> query(String name) =>
      _values.where((m) => m.name == name);
  Map<String, num> summary() => {
    for (final name in _values.map((e) => e.name).toSet())
      name: _values
          .where((e) => e.name == name)
          .map((e) => e.value)
          .fold<num>(0, (a, b) => a + b),
  };
}
