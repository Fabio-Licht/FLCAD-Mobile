import '../models/knowledge_models.dart';

class KnowledgeProbabilityEngine {
  const KnowledgeProbabilityEngine();
  KnowledgeInference combine(
    String conclusion,
    Iterable<KnowledgeInference> inferences,
  ) {
    final values = inferences.where((i) => i.conclusion == conclusion).toList();
    if (values.isEmpty) throw ArgumentError('Supporting inference required');
    var complement = 1.0;
    for (final i in values) {
      complement *= 1 - i.confidence;
    }
    final confidence = (1 - complement).clamp(0, 1).toDouble();
    return KnowledgeInference(
      conclusion: conclusion,
      confidence: confidence,
      explanation: 'Combined ${values.length} independent knowledge signals.',
      evidence: values.expand((i) => i.evidence).toList(),
      ruleIds: values.expand((i) => i.ruleIds).toSet().toList(),
    );
  }
}
