import '../models/intelligence_models.dart';

class ExplanationEngine {
  const ExplanationEngine();
  String explain(StrategyDecision decision, ValidationAssessment validation) {
    final evidence = decision.selected.evidence
            .map((e) => '${e.description}: ${e.value.toStringAsFixed(3)}')
            .join('; '),
        findings = validation.findings.isEmpty
            ? 'no blocking findings'
            : validation.findings.join('; ');
    return '${decision.explanation} Evidence: $evidence. Validation ${(validation.score * 100).toStringAsFixed(1)}%: $findings.';
  }
}
