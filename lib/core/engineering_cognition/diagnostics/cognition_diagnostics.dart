class CognitionDiagnostic {
  const CognitionDiagnostic(this.code, this.message, this.entityId);
  final String code, message, entityId;
}

class CognitionDiagnostics {
  final List<CognitionDiagnostic> _values = [];
  List<CognitionDiagnostic> get values => List.unmodifiable(_values);
  void report(CognitionDiagnostic value) => _values.add(value);
}
