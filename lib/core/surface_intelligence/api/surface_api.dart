import '../engine/surface_intelligence_engine.dart';
import '../models/surface_models.dart';

class SurfaceIntelligenceApi {
  const SurfaceIntelligenceApi(this.engine);
  final SurfaceIntelligenceEngine engine;
  Future<SurfacePlan> plan(SurfacePlanningRequest request) =>
      engine.plan(request);
  SurfacePlan get current =>
      engine.current ?? (throw StateError('No surface plan'));
  SurfaceExplanationView explain(String candidateId) {
    final value = engine.explain(candidateId);
    return SurfaceExplanationView(
      value.candidateId,
      value.answer,
      value.evidenceIds,
      value.discardedAlternatives,
    );
  }

  List<String> validate() => engine.validate(current);
}

class SurfaceExplanationView {
  const SurfaceExplanationView(
    this.candidateId,
    this.answer,
    this.evidenceIds,
    this.discardedAlternatives,
  );
  final String candidateId, answer;
  final List<String> evidenceIds, discardedAlternatives;
}
