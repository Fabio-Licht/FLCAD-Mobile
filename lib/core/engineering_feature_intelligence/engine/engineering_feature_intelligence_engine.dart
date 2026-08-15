import '../../primitive_intelligence/models/primitive_intelligence_models.dart';
import '../advisor/engineering_feature_advisor.dart';
import '../analytics/engineering_feature_analytics.dart';
import '../confidence/feature_confidence_engine.dart';
import '../graph/feature_graph_builder.dart';
import '../integration/engineering_feature_integration.dart';
import '../library/engineering_feature_library.dart';
import '../models/engineering_feature_models.dart';
import '../reasoning/feature_reasoning_engines.dart';
import '../reasoning/feature_contract_engines.dart';
import '../repository/engineering_feature_repository.dart';

class EngineeringFeatureIntelligenceEngine {
  EngineeringFeatureIntelligenceEngine({
    required this.repository,
    required this.confidence,
    this.library = const EngineeringFeatureLibrary(),
    this.graphBuilder = const FeatureGraphBuilder(),
    this.manufacturing = const ManufacturingContextIntelligence(),
    this.strategies = const ReconstructionStrategyEngine(),
    this.canonical = const CanonicalFeatureEngine(),
    this.dnaBuilder = const EngineeringDnaBuilder(),
    this.advisor = const EngineeringFeatureAdvisor(),
    this.ranking = const FeatureRankingEngine(),
    this.integration,
  });
  final EngineeringFeatureRepository repository;
  final FeatureConfidenceEngine confidence;
  final EngineeringFeatureLibrary library;
  final FeatureGraphBuilder graphBuilder;
  final ManufacturingContextIntelligence manufacturing;
  final ReconstructionStrategyEngine strategies;
  final CanonicalFeatureEngine canonical;
  final EngineeringDnaBuilder dnaBuilder;
  final EngineeringFeatureAdvisor advisor;
  final FeatureRankingEngine ranking;
  final EngineeringFeatureIntegration? integration;

  EngineeringFeatureSession analyze({
    required String sessionId,
    required PrimitiveIntelligenceSession primitives,
  }) {
    final ordered = [...primitives.hypotheses]
      ..sort((a, b) => a.id.compareTo(b.id));
    final hypotheses = <EngineeringFeatureHypothesis>[
      for (final primitive in ordered)
        _hypothesis(
          sessionId,
          primitive,
          primitives,
          library.select(primitive),
        ),
    ];
    for (final pattern in primitives.patterns.where(
      (p) =>
          p.kind == PatternKind.circular || p.kind == PatternKind.repeatedHoles,
    )) {
      final member = ordered
          .where((e) => pattern.memberIds.contains(e.primitive.id))
          .firstOrNull;
      if (member != null) {
        hypotheses.add(
          _hypothesis(
            '$sessionId:composite',
            member,
            primitives,
            EngineeringFeatureType.flange,
            compositeIds: pattern.memberIds,
          ),
        );
      }
    }
    final ranked = ranking.rank(hypotheses);
    final session = EngineeringFeatureSession(
      id: sessionId,
      context: primitives.context,
      hypotheses: ranked,
      decisions: const [],
      dna: dnaBuilder.build(ranked),
    );
    repository.add(session);
    integration?.onSessionChanged(session);
    return session;
  }

  EngineeringFeatureHypothesis _hypothesis(
    String sessionId,
    PrimitiveHypothesis primitive,
    PrimitiveIntelligenceSession source,
    EngineeringFeatureType type, {
    List<String>? compositeIds,
  }) {
    final id = '$sessionId:${primitive.primitive.id}:${type.name}';
    final graph = graphBuilder.build(
      id: '$id:graph',
      primitive: primitive,
      source: source,
    );
    final evidence = [
      for (final item in primitive.evidence)
        FeatureEvidence(
          id: '$id:${item.field}',
          source: item.source,
          description: item.justification,
          primitiveIds: compositeIds ?? [primitive.primitive.id],
          score: primitive.scores.confidence,
        ),
      for (final edge in graph.edges)
        FeatureEvidence(
          id: '$id:${edge.from}:${edge.to}',
          source: 'featureGraph.${edge.relationship.name}',
          description: '${edge.from} ${edge.relationship.name} ${edge.to}',
          primitiveIds: compositeIds ?? [primitive.primitive.id],
          score: edge.score,
        ),
    ];
    final measures = primitive.primitive.measures;
    final scores = confidence.calculate({
      'geometric':
          measures['featureGeometricScore'] ?? primitive.scores.confidence,
      'topology': measures['featureTopologyScore'] ?? 0,
      'functional': measures['featureFunctionalScore'] ?? 0,
      'manufacturing':
          measures['featureManufacturingScore'] ??
          primitive.scores.manufacturingRelevance,
      'symmetry':
          measures['featureSymmetryScore'] ?? primitive.symmetry?.score ?? 0,
      'context': measures['featureContextScore'] ?? 0,
      'history': measures['featureHistoryScore'] ?? 0,
    });
    final candidates =
        library
            .candidates(primitive)
            .map((e) => e.name)
            .where((e) => e != type.name)
            .toList()
          ..sort();
    return EngineeringFeatureHypothesis(
      id: id,
      type: type,
      function: library.function(
        type,
        declaredCode: measures['featureFunctionCode']?.toInt(),
      ),
      graph: graph,
      confidenceTree: confidence.tree(id, scores, evidence),
      scores: scores,
      evidence: evidence,
      justification:
          '${type.name} inferred from primitives ${compositeIds ?? [primitive.primitive.id]}, graph relationships ${graph.edges.map((e) => e.relationship.name).toList()}, and manufacturing context ${manufacturing.infer(type)}.',
      discardedHypotheses: candidates,
      strategy: strategies.build(type),
      canonicalSuggestion: canonical.suggest(type, primitive),
    );
  }

  EngineeringFeatureSession decide({
    required String sessionId,
    required String hypothesisId,
    required FeatureDecisionType type,
    required String reason,
  }) {
    final current = _require(sessionId);
    if (!current.hypotheses.any((e) => e.id == hypothesisId)) {
      throw StateError('Unknown engineering feature hypothesis: $hypothesisId');
    }
    final updated = current.copyWith(
      decisions: [
        ...current.decisions,
        FeatureDecision(
          hypothesisId: hypothesisId,
          type: type,
          reason: reason,
          sequence: current.decisions.length,
        ),
      ],
    );
    repository.update(updated);
    integration?.onSessionChanged(updated);
    return updated;
  }

  EngineeringFeatureSession rollback(String id, int count) {
    final value = repository.rollback(id, count);
    integration?.onSessionChanged(value);
    return value;
  }

  List<EngineeringFeatureRecommendation> recommendations(String id) =>
      advisor.advise(_require(id));
  EngineeringFeatureAnalytics analytics(
    String id, {
    Duration analysisDuration = Duration.zero,
  }) => EngineeringFeatureAnalytics.fromSession(
    _require(id),
    analysisDuration: analysisDuration,
  );
  Future<void> persist(String id) => repository.persist(
    id,
    recommendations: recommendations(id),
    analytics: analytics(id),
  );
  EngineeringFeatureSession _require(String id) {
    final value = repository.find(id);
    if (value == null) {
      throw StateError('Unknown engineering feature session: $id');
    }
    return value;
  }
}
