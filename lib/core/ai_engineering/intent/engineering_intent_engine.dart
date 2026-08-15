import '../confidence/confidence_engine.dart';
import '../context/engineering_context.dart';
import '../features/feature_vector_builder.dart';
import '../models/ai_engineering_models.dart';

class EngineeringIntentEngine {
  const EngineeringIntentEngine({
    required this.confidenceEngine,
    this.featureVectorBuilder = const FeatureVectorBuilder(),
  });
  final ConfidenceEngine confidenceEngine;
  final FeatureVectorBuilder featureVectorBuilder;

  EngineeringIntent interpret({
    required String sessionId,
    required EngineeringContext context,
    required Iterable<EngineeringIntentType> requestedIntents,
  }) {
    final vector = featureVectorBuilder.build(context);
    final types = requestedIntents.toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final candidates = types.map((type) {
      final evidence = _evidence(type, context, vector);
      final score = confidenceEngine.calculate(
        geometric: _declaredScore(context, 'geometricScore'),
        topology: _declaredScore(context, 'topologyScore'),
        manufacturing: _declaredScore(context, 'manufacturingScore'),
        continuity: _declaredScore(context, 'continuityScore'),
        symmetry: _declaredScore(context, 'symmetryScore'),
        history: _declaredScore(context, 'historyScore'),
        userPreference: _declaredScore(context, 'userPreferenceScore'),
      );
      return IntentCandidate(
        id: '$sessionId:${type.name}',
        type: type,
        title: '${type.name} intent hypothesis',
        rationale:
            'Derived only from the supplied engineering context snapshot.',
        evidence: evidence,
        confidence: score,
      );
    }).toList();
    return EngineeringIntent(
      id: '$sessionId:intent',
      sessionId: sessionId,
      candidates: candidates,
    );
  }

  List<IntentEvidence> _evidence(
    EngineeringIntentType type,
    EngineeringContext context,
    EngineeringFeatureVector vector,
  ) => [
    IntentEvidence(
      source: 'engineeringContext.activeModule',
      description: 'Active module for ${type.name} hypothesis',
      value: context.activeModule == type.name ? 1 : 0,
    ),
    IntentEvidence(
      source: 'featureVector.patches',
      description: 'Deterministic patch count',
      value: vector['patches'],
    ),
    IntentEvidence(
      source: 'featureVector.boundaries',
      description: 'Deterministic boundary count',
      value: vector['boundaries'],
    ),
  ];

  double _declaredScore(EngineeringContext context, String key) {
    final value = context.metrics[key] ?? 0;
    if (value < 0 || value > 1) {
      throw RangeError.range(value, 0, 1, key);
    }
    return value;
  }
}
