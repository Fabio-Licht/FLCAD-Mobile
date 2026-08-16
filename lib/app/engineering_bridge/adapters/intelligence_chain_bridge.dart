import '../../../core/ai_engineering/models/ai_engineering_models.dart';
import '../../../core/engineering_feature_intelligence/api/engineering_feature_intelligence_api.dart';
import '../../../core/engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../../core/primitive_intelligence/api/primitive_intelligence_api.dart';
import '../../../core/primitive_intelligence/models/primitive_intelligence_models.dart';
import '../../../core/professional_recognition/models/professional_recognition_models.dart';
import '../contracts/bridge_context.dart';

class IntelligenceChainResult {
  const IntelligenceChainResult(this.primitives, this.features);
  final PrimitiveIntelligenceSession primitives;
  final EngineeringFeatureSession features;
}

class IntelligenceChainBridge {
  const IntelligenceChainBridge({
    required this.primitives,
    required this.features,
  });
  final PrimitiveIntelligenceApi primitives;
  final EngineeringFeatureIntelligenceApi features;

  IntelligenceChainResult analyze({
    required BridgeContext context,
    required ProfessionalRecognitionReport recognition,
    required String sessionId,
  }) {
    if (recognition.primitives.isEmpty) {
      throw StateError(
        'Recognition produced no primitive result for the intelligence chain.',
      );
    }
    final observations = recognition.primitives.map((professional) {
      final candidate = professional.recognition.winner;
      final measures = <String, double>{
        for (final entry in candidate.parameters.entries)
          if (entry.value is num) entry.key: (entry.value as num).toDouble(),
        'rms': candidate.statistics.rms,
        'coverage': candidate.statistics.coverage,
        'stability': candidate.statistics.stability,
      };
      final vectors = <String, List<double>>{
        for (final entry in candidate.parameters.entries)
          if (entry.value is List &&
              (entry.value as List).every((e) => e is num))
            entry.key: (entry.value as List)
                .cast<num>()
                .map((e) => e.toDouble())
                .toList(),
      };
      return PrimitiveObservation(
        id: candidate.id,
        type: candidate.type,
        measures: measures,
        vectors: vectors,
        adjacentIds: recognition.relations
            .where((relation) => relation.primitiveIds.contains(candidate.id))
            .expand(
              (relation) =>
                  relation.primitiveIds.where((id) => id != candidate.id),
            )
            .toSet(),
        recognitionConfidence: professional.recognition.dna.confidence,
      );
    }).toList();
    final primitiveSession = primitives.analyze(
      sessionId: '$sessionId:primitives',
      context: EngineeringContextSnapshot(
        projectId: context.projectId,
        activePartId: context.meshId,
        values: {
          'meshFingerprint': context.meshFingerprint,
          'regionId': context.region?.id,
          'source': 'EngineeringInteractionBridge',
        },
      ),
      primitives: observations,
    );
    final featureSession = features.analyze(
      sessionId: '$sessionId:features',
      primitives: primitiveSession,
    );
    return IntelligenceChainResult(primitiveSession, featureSession);
  }
}
