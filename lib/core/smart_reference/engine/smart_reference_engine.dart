import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../advisor/reference_strategy_advisor.dart';
import '../analytics/smart_reference_analytics.dart';
import '../builder/reference_candidate_builder.dart';
import '../graph/reference_dependency_graph_builder.dart';
import '../integration/smart_reference_integration.dart';
import '../intelligence/reference_intelligence_engines.dart';
import '../models/smart_reference_models.dart';
import '../repository/smart_reference_repository.dart';

class SmartReferenceEngine {
  SmartReferenceEngine({
    required this.repository,
    required this.candidateBuilder,
    this.graphBuilder = const ReferenceDependencyGraphBuilder(),
    this.datumIntelligence = const DatumIntelligence(),
    this.coordinateSystemIntelligence = const CoordinateSystemIntelligence(),
    this.alignmentStrategies = const AlignmentStrategyGenerator(),
    this.advisor = const ReferenceStrategyAdvisor(),
    this.integration,
  });
  final SmartReferenceRepository repository;
  final ReferenceCandidateBuilder candidateBuilder;
  final ReferenceDependencyGraphBuilder graphBuilder;
  final DatumIntelligence datumIntelligence;
  final CoordinateSystemIntelligence coordinateSystemIntelligence;
  final AlignmentStrategyGenerator alignmentStrategies;
  final ReferenceStrategyAdvisor advisor;
  final SmartReferenceIntegration? integration;
  SmartReferenceSession analyze({
    required String sessionId,
    required EngineeringFeatureSession features,
  }) {
    final candidates = candidateBuilder.build(sessionId, features);
    final session = SmartReferenceSession(
      id: sessionId,
      context: features.context,
      candidates: candidates,
      graph: graphBuilder.build(candidates),
      datums: datumIntelligence.analyze(candidates),
      coordinateSystems: coordinateSystemIntelligence.analyze(candidates),
      strategies: alignmentStrategies.generate(sessionId, candidates),
      decisions: const [],
    );
    repository.add(session);
    integration?.onSessionChanged(session);
    return session;
  }

  SmartReferenceSession decide({
    required String sessionId,
    required String referenceId,
    required ReferenceDecisionType type,
    required String reason,
  }) {
    final current = _require(sessionId);
    if (!current.candidates.any((e) => e.id == referenceId)) {
      throw StateError('Unknown reference candidate: $referenceId');
    }
    final updated = current.copyWith(
      decisions: [
        ...current.decisions,
        ReferenceDecision(
          referenceId: referenceId,
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

  SmartReferenceSession rollback(String id, int count) {
    final value = repository.rollback(id, count);
    integration?.onSessionChanged(value);
    return value;
  }

  List<ReferenceRecommendation> recommendations(String id) =>
      advisor.advise(_require(id));
  SmartReferenceAnalytics analytics(
    String id, {
    Duration analysisDuration = Duration.zero,
  }) => SmartReferenceAnalytics.fromSession(
    _require(id),
    analysisDuration: analysisDuration,
  );
  Future<void> persist(String id) => repository.persist(
    id,
    recommendations: recommendations(id),
    analytics: analytics(id),
  );
  SmartReferenceSession _require(String id) {
    final value = repository.find(id);
    if (value == null) {
      throw StateError('Unknown smart reference session: $id');
    }
    return value;
  }
}
