import '../../ai_engineering/models/ai_engineering_models.dart';
import '../advisor/primitive_advisor.dart';
import '../alignment/alignment_intelligence.dart';
import '../analytics/primitive_intelligence_analytics.dart';
import '../classification/primitive_classification_engine.dart';
import '../evidence/primitive_evidence_builder.dart';
import '../integration/primitive_intelligence_integration.dart';
import '../models/primitive_intelligence_models.dart';
import '../ranking/primitive_ranking_engine.dart';
import '../reasoning/primitive_reasoning_engines.dart';
import '../repository/primitive_intelligence_repository.dart';

class PrimitiveIntelligenceEngine {
  PrimitiveIntelligenceEngine({
    required this.repository,
    required this.ranking,
    this.evidenceBuilder = const PrimitiveEvidenceBuilder(),
    this.classification = const PrimitiveClassificationEngine(),
    this.alignment = const AlignmentIntelligence(),
    this.axisIntelligence = const AxisIntelligence(),
    this.symmetryIntelligence = const SymmetryIntelligence(),
    this.patternIntelligence = const PatternIntelligence(),
    this.manufacturingIntelligence = const ManufacturingIntelligence(),
    this.advisor = const PrimitiveAdvisor(),
    this.integration,
  });
  final PrimitiveIntelligenceRepository repository;
  final PrimitiveRankingEngine ranking;
  final PrimitiveEvidenceBuilder evidenceBuilder;
  final PrimitiveClassificationEngine classification;
  final AlignmentIntelligence alignment;
  final AxisIntelligence axisIntelligence;
  final SymmetryIntelligence symmetryIntelligence;
  final PatternIntelligence patternIntelligence;
  final ManufacturingIntelligence manufacturingIntelligence;
  final PrimitiveAdvisor advisor;
  final PrimitiveIntelligenceIntegration? integration;

  PrimitiveIntelligenceSession analyze({
    required String sessionId,
    required EngineeringContextSnapshot context,
    required Iterable<PrimitiveObservation> primitives,
  }) {
    final ordered = primitives.toList()..sort((a, b) => a.id.compareTo(b.id));
    final hypotheses = ordered.map((primitive) {
      final function = classification.classify(primitive);
      final evidence = evidenceBuilder.build(primitive);
      final scores = ranking.score(primitive);
      return PrimitiveHypothesis(
        id: '$sessionId:${primitive.id}:${function.name}',
        primitive: primitive,
        function: function,
        scores: scores,
        evidence: evidence,
        justification:
            '${primitive.type.name} classified as ${function.name} from ${evidence.map((e) => e.field).join(', ')}.',
        suggestion: manufacturingIntelligence.suggestion(primitive, function),
        alignment: alignment.analyze(primitive),
        axis: axisIntelligence.analyze(primitive),
        symmetry: symmetryIntelligence.analyze(primitive),
      );
    });
    final session = PrimitiveIntelligenceSession(
      id: sessionId,
      context: context,
      hypotheses: ranking.rank(hypotheses),
      patterns: patternIntelligence.analyze(ordered),
      decisions: const [],
    );
    repository.add(session);
    integration?.onSessionChanged(session);
    return session;
  }

  PrimitiveIntelligenceSession decide({
    required String sessionId,
    required String hypothesisId,
    required PrimitiveDecisionType type,
    required String reason,
  }) {
    final current = _require(sessionId);
    if (!current.hypotheses.any((e) => e.id == hypothesisId)) {
      throw StateError('Unknown primitive hypothesis: $hypothesisId');
    }
    final decisions = [
      ...current.decisions,
      PrimitiveDecision(
        hypothesisId: hypothesisId,
        type: type,
        reason: reason,
        sequence: current.decisions.length,
      ),
    ];
    final updated = current.copyWith(decisions: decisions);
    repository.update(updated);
    integration?.onSessionChanged(updated);
    return updated;
  }

  PrimitiveIntelligenceSession rollback(String sessionId, int decisionCount) {
    final value = repository.rollback(sessionId, decisionCount);
    integration?.onSessionChanged(value);
    return value;
  }

  List<PrimitiveRecommendation> recommendations(String id) =>
      advisor.advise(_require(id));
  PrimitiveIntelligenceAnalytics analytics(
    String id, {
    Duration analysisDuration = Duration.zero,
  }) => PrimitiveIntelligenceAnalytics.fromSession(
    _require(id),
    analysisDuration: analysisDuration,
  );
  Future<void> persist(String id) => repository.persist(
    id,
    recommendations: recommendations(id),
    analytics: analytics(id),
  );
  PrimitiveIntelligenceSession _require(String id) {
    final value = repository.find(id);
    if (value == null) {
      throw StateError('Unknown primitive intelligence session: $id');
    }
    return value;
  }
}
