class StandardReference {
  const StandardReference(
    this.id,
    this.organization,
    this.topic, {
    this.edition,
    this.uri,
  });
  final String id, organization, topic;
  final String? edition, uri;
}

class StandardsRegistry {
  StandardsRegistry();
  final Map<String, StandardReference> _items = {};
  Iterable<StandardReference> get items => _items.values;
  void register(StandardReference reference) =>
      _items[reference.id] = reference;
  StandardReference? find(String id) => _items[id];
  factory StandardsRegistry.foundation() {
    final r = StandardsRegistry();
    for (final item in const [
      StandardReference('ISO', 'ISO', 'International engineering standards'),
      StandardReference('DIN', 'DIN', 'German engineering standards'),
      StandardReference('ASME', 'ASME', 'Mechanical engineering standards'),
      StandardReference('ANSI', 'ANSI', 'US standards coordination'),
      StandardReference('JIS', 'JIS', 'Japanese industrial standards'),
      StandardReference(
        'GD&T',
        'neutral',
        'Geometric dimensioning and tolerancing',
      ),
      StandardReference(
        'AP242',
        'ISO',
        'STEP managed model-based 3D engineering',
      ),
      StandardReference('STEP', 'ISO', 'Product model data exchange'),
    ]) {
      r.register(item);
    }
    return r;
  }
}
