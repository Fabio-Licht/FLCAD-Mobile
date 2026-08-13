class EngineeringDiagnostic {
  const EngineeringDiagnostic(
    this.code,
    this.message,
    this.severity,
    this.data,
  );
  final String code, message, severity;
  final Map<String, dynamic> data;
}

class EngineeringDiagnostics {
  final List<EngineeringDiagnostic> values = [];
  void add(EngineeringDiagnostic value) => values.add(value);
  bool get healthy =>
      !values.any((v) => v.severity == 'error' || v.severity == 'critical');
}
