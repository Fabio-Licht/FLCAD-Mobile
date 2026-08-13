class IntelligenceDiagnostic {
  const IntelligenceDiagnostic(this.code, this.message, this.context);
  final String code, message;
  final Map<String, dynamic> context;
}

class IntelligenceDiagnostics {
  final List<IntelligenceDiagnostic> _items = [];
  List<IntelligenceDiagnostic> get items => List.unmodifiable(_items);
  void report(IntelligenceDiagnostic value) => _items.add(value);
}
