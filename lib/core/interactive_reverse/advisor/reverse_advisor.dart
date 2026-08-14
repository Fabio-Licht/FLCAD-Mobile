import '../models/interactive_models.dart';

class AdvisorResponse {
  const AdvisorResponse({
    required this.region,
    required this.recognitionReason,
    required this.feature,
    required this.datum,
    required this.alignment,
    required this.expectedGain,
    required this.confidence,
    required this.explanation,
    required this.advantages,
    required this.alternatives,
  });
  final String region,
      recognitionReason,
      feature,
      datum,
      alignment,
      explanation;
  final double expectedGain, confidence;
  final List<String> advantages, alternatives;
  Map<String, dynamic> toJson() => {
    'region': region,
    'recognitionReason': recognitionReason,
    'feature': feature,
    'datum': datum,
    'alignment': alignment,
    'expectedGain': expectedGain,
    'confidence': confidence,
    'explanation': explanation,
    'advantages': advantages,
    'alternatives': alternatives,
  };
}

class ReverseAdvisor {
  const ReverseAdvisor();
  AdvisorResponse advise(
    InteractiveSelection selection,
    List<ContextSuggestion> suggestions,
  ) {
    final first = suggestions.first;
    return AdvisorResponse(
      region: selection.type.name,
      recognitionReason: 'Evidence supplied by the recognition context.',
      feature: first.label,
      datum: selection.type == SelectionType.recognizedCylinder
          ? 'Datum Axis'
          : 'Datum Plane',
      alignment: selection.type == SelectionType.recognizedCylinder
          ? 'Axis Alignment'
          : 'Plane Alignment',
      expectedGain: first.expectedGain,
      confidence: selection.confidence,
      explanation: first.explanation,
      advantages: first.advantages,
      alternatives: first.alternatives,
    );
  }
}
