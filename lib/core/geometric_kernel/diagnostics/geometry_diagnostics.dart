class GeometryDiagnostic {
  const GeometryDiagnostic(this.code, this.message);
  final String code, message;
}

class GeometryDiagnostics {
  final List<GeometryDiagnostic> _items = [];
  List<GeometryDiagnostic> get items => List.unmodifiable(_items);
  void report(GeometryDiagnostic item) => _items.add(item);
}
