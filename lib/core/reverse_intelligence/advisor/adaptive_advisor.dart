import '../models/intelligence_models.dart';

class AdvisorSuggestion {
  const AdvisorSuggestion(this.message, this.priority, this.evidence);
  final String message;
  final double priority;
  final List<Evidence> evidence;
}

class AdaptiveAdvisor {
  const AdaptiveAdvisor();
  List<AdvisorSuggestion> advise(ReasoningSnapshot twin) {
    final result = <AdvisorSuggestion>[];
    if (!twin.observation.isWatertight) {
      result.add(
        AdvisorSuggestion(
          'Repair or delimit open boundaries before high-confidence reconstruction',
          .9,
          twin.observation.evidence
              .where((e) => e.id == 'boundary_edges')
              .toList(),
        ),
      );
    }
    if (twin.decision.confidence < .6) {
      result.add(
        AdvisorSuggestion(
          'Request user confirmation between competing strategies',
          .8,
          twin.decision.selected.evidence,
        ),
      );
    }
    return result;
  }
}
