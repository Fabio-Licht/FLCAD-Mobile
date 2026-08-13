class TriangleSelection {
  TriangleSelection(Iterable<int> indices)
    : _indices = Set.unmodifiable(indices);
  final Set<int> _indices;
  Set<int> get indices => _indices;
  int get length => _indices.length;
  bool contains(int index) => _indices.contains(index);
  TriangleSelection union(TriangleSelection other) =>
      TriangleSelection(_indices.union(other._indices));
  TriangleSelection intersect(TriangleSelection other) =>
      TriangleSelection(_indices.intersection(other._indices));
  TriangleSelection subtract(TriangleSelection other) =>
      TriangleSelection(_indices.difference(other._indices));
  List<List<int>> toRanges() {
    final sorted = _indices.toList()..sort();
    final ranges = <List<int>>[];
    for (final value in sorted) {
      if (ranges.isEmpty || value > ranges.last[1] + 1) {
        ranges.add([value, value]);
      } else {
        ranges.last[1] = value;
      }
    }
    return ranges;
  }

  factory TriangleSelection.fromRanges(List<dynamic> ranges) =>
      TriangleSelection(
        ranges.expand((range) {
          final values = (range as List).cast<int>();
          return Iterable.generate(
            values[1] - values[0] + 1,
            (i) => values[0] + i,
          );
        }),
      );
}
