import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../analysis/engineering_score_engine.dart';
import '../analysis/project_analyzer.dart';
import '../analytics/intelligence_analytics.dart';
import '../graph/intelligence_graph.dart';
import '../history/intelligence_history.dart';
import '../knowledge/knowledge_base.dart';
import '../models/intelligence_models.dart';
import '../recommendations/recommendation_engine.dart';
import '../repository/intelligence_repository.dart';
import '../runtime/intelligence_runtime.dart';
import '../validation/intelligence_validation.dart';

class EngineeringIntelligenceEngine {
  EngineeringIntelligenceEngine({
    required this.kernel,
    required this.repository,
    EngineeringIntelligenceRuntime? runtime,
    IntelligenceAnalytics? analytics,
    IntelligenceHistory? history,
  }) : runtime = runtime ?? EngineeringIntelligenceRuntime(),
       analytics = analytics ?? IntelligenceAnalytics(),
       history = history ?? IntelligenceHistory();
  final GeometryKernelAPI kernel;
  final IntelligenceRepository repository;
  final EngineeringIntelligenceRuntime runtime;
  final IntelligenceAnalytics analytics;
  final IntelligenceHistory history;
  final knowledge = EngineeringKnowledgeBase();
  final graph = IntelligenceGraph();
  final Map<String, EngineeringAnalysis> analyses = {};
  final Map<String, EngineeringRecommendation> recommendations = {};
  final Map<String, EngineeringDiagnostic> diagnostics = {};
  final validator = const IntelligenceValidator();
  EngineeringScore? currentScore;
  Future<EngineeringAnalysis> analyze(
    IntelligenceAnalysisType type,
    ProjectKnowledgeSnapshot snapshot,
  ) async {
    final validation = validator.validate(snapshot);
    if (!validation.valid) {
      throw StateError(validation.issues.map((e) => e.message).join('; '));
    }
    knowledge.register(snapshot);
    final score = const EngineeringScoreEngine().calculate(snapshot),
        projectDiagnostics = const ProjectAnalyzer().analyze(
          type,
          snapshot,
          score,
        ),
        generated = const RecommendationEngine().generate(snapshot, score),
        health = await kernel.healthCheck(),
        allDiagnostics = [
          ...projectDiagnostics,
          if (health.status == KernelHealthStatus.unavailable)
            EngineeringDiagnostic(
              analysisType: type,
              message:
                  'Geometry kernel unavailable; geometry-dependent evidence excluded',
              severity: 'information',
              affectedIds: const [],
            ),
        ],
        analysis = EngineeringAnalysis(
          type: type,
          snapshot: snapshot,
          score: score,
          diagnostics: allDiagnostics,
          recommendations: generated,
        );
    analyses[analysis.id] = analysis;
    currentScore = score;
    graph.add(analysis.id);
    for (final recommendation in generated) {
      recommendations[recommendation.id] = recommendation;
      graph.connect(analysis.id, recommendation.id);
      graph.relate(graph.impactRelations, recommendation.id, analysis.id);
      for (final feature in recommendation.affectedFeatures) {
        graph.relate(graph.featureRelations, feature, recommendation.id);
      }
      for (final reference in recommendation.affectedReferences) {
        graph.relate(graph.referenceRelations, reference, recommendation.id);
      }
      for (final region in recommendation.affectedRegions) {
        graph.relate(graph.validationRelations, region, recommendation.id);
      }
    }
    for (final diagnostic in allDiagnostics) {
      diagnostics[diagnostic.id] = diagnostic;
    }
    _track(type, generated, allDiagnostics);
    history.record(IntelligenceHistoryAction.analyzed, analysis.id);
    analytics.historicalRecords++;
    return analysis;
  }

  void _track(
    IntelligenceAnalysisType type,
    List<EngineeringRecommendation> generated,
    List<EngineeringDiagnostic> found,
  ) {
    if (type == IntelligenceAnalysisType.project) analytics.projectAnalyses++;
    if (type == IntelligenceAnalysisType.feature) analytics.featureAnalyses++;
    analytics.recommendations += generated.length;
    analytics.diagnostics += found.length;
    analytics.scoreUpdates++;
    analytics.healthUpdates++;
    analytics.timelineUpdates += generated.length;
    analytics.totalConfidence += generated.fold(
      0,
      (sum, r) => sum + r.confidence,
    );
  }

  Future<EngineeringAnalysis> analyzeProject(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.project, s);
  Future<EngineeringAnalysis> analyzeFeature(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.feature, s);
  Future<EngineeringAnalysis> analyzeReference(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.reference, s);
  Future<EngineeringAnalysis> analyzeAlignment(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.alignment, s);
  Future<EngineeringAnalysis> analyzeValidation(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.validation, s);
  Future<EngineeringAnalysis> analyzeTimeline(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.timeline, s);
  Future<EngineeringAnalysis> analyzeQuality(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.quality, s);
  Future<EngineeringAnalysis> analyzeDependencies(ProjectKnowledgeSnapshot s) =>
      analyze(IntelligenceAnalysisType.dependencies, s);
  Future<EngineeringAnalysis> analyzeManufacturability(
    ProjectKnowledgeSnapshot s,
  ) => analyze(IntelligenceAnalysisType.manufacturability, s);
  Future<EngineeringAnalysis> analyzeModelingStrategy(
    ProjectKnowledgeSnapshot s,
  ) => analyze(IntelligenceAnalysisType.modelingStrategy, s);
  void decide(String id, RecommendationDecision decision) {
    final recommendation =
        recommendations[id] ??
        (throw StateError('Unknown recommendation: $id'));
    if (recommendation.decision != RecommendationDecision.pending) {
      throw StateError('Recommendation already decided: $id');
    }
    recommendation.decision = decision;
    final action = switch (decision) {
      RecommendationDecision.accepted => IntelligenceHistoryAction.accepted,
      RecommendationDecision.rejected => IntelligenceHistoryAction.rejected,
      RecommendationDecision.ignored => IntelligenceHistoryAction.ignored,
      RecommendationDecision.pending => throw StateError(
        'Pending is not a decision',
      ),
    };
    history.record(action, id);
    analytics.historicalRecords++;
    if (decision == RecommendationDecision.accepted) analytics.accepted++;
    if (decision == RecommendationDecision.rejected) analytics.rejected++;
    if (decision == RecommendationDecision.ignored) analytics.ignored++;
  }

  void recordImpact(
    String recommendationId, {
    required double impact,
    required double gain,
    required double accuracy,
  }) {
    if (!recommendations.containsKey(recommendationId)) {
      throw StateError('Unknown recommendation: $recommendationId');
    }
    history.record(
      IntelligenceHistoryAction.impactObserved,
      recommendationId,
      impact: impact,
      gain: gain,
      accuracy: accuracy,
    );
    analytics.historicalRecords++;
    analytics.observedGain += gain;
  }

  Future<void> persist() => repository.save(
    analyses: analyses.values,
    recommendations: recommendations.values,
    diagnostics: diagnostics.values,
    history: history,
    analytics: analytics,
    score: currentScore,
  );
}
