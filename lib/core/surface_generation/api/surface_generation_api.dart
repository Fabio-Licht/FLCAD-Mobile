import '../../adaptive_surface/models/surface_geometry.dart';
import '../../surface_intelligence/models/surface_models.dart';
import '../builders/analytic_surface_builders.dart';
import '../engine/surface_generation_engine.dart';
import '../models/surface_generation_models.dart';

class SurfaceGenerationApi {
  SurfaceGenerationApi(this.engine)
    : plane = PlaneSurfaceBuilder(engine),
      cylinder = CylinderSurfaceBuilder(engine),
      cone = ConeSurfaceBuilder(engine),
      sphere = SphereSurfaceBuilder(engine),
      torus = TorusSurfaceBuilder(engine);
  final SurfaceGenerationEngine engine;
  final PlaneSurfaceBuilder plane;
  final CylinderSurfaceBuilder cylinder;
  final ConeSurfaceBuilder cone;
  final SphereSurfaceBuilder sphere;
  final TorusSurfaceBuilder torus;
  Future<List<SurfaceGenerationResult>> generateApproved(
    SurfacePlan plan,
    Map<String, Map<String, dynamic>> parameters,
  ) async {
    final approved = plan.selectedStrategyIds
        .map((id) => plan.strategies.where((e) => e.id == id).firstOrNull)
        .whereType<SurfaceStrategy>()
        .map(
          (strategy) =>
              plan.candidates.firstWhere((e) => e.id == strategy.candidateId),
        )
        .where(
          (e) => {
            SurfaceKind.plane,
            SurfaceKind.cylinder,
            SurfaceKind.cone,
            SurfaceKind.sphere,
            SurfaceKind.torus,
          }.contains(e.kind),
        );
    final results = <SurfaceGenerationResult>[];
    for (final candidate in approved) {
      results.add(
        await engine.generate(
          SurfaceGenerationRequest(
            candidate: candidate,
            parameters: parameters[candidate.id] ?? const {},
          ),
        ),
      );
    }
    return results;
  }

  SurfaceGenerationAdvice explain(String surfaceId, double predictedQuality) {
    final surface =
        engine.registry.find(surfaceId) ??
        (throw StateError('Surface $surfaceId not found'));
    return engine.advisor.explain(surface, predictedQuality: predictedQuality);
  }

  Future<List<GeneratedSurface>> load() async {
    final surfaces = await engine.repository.loadAll();
    for (final surface in surfaces) {
      engine.registry.register(surface);
    }
    return surfaces;
  }
}
