class ReconstructionDiagnostic {
  const ReconstructionDiagnostic(this.code, this.message, this.stageId);
  final String code, message;
  final String? stageId;
}

class ReconstructionDiagnostics {
  final List<ReconstructionDiagnostic> _values = [];
  List<ReconstructionDiagnostic> get values => List.unmodifiable(_values);
  void report(ReconstructionDiagnostic value) => _values.add(value);
}
