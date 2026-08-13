import '../../surface_intelligence/models/surface_models.dart';
import '../advisor/freeform_advisor.dart';
import '../analytics/hybrid_surface_analytics.dart';
import '../engine/hybrid_surface_engine.dart';
import '../models/hybrid_surface_models.dart';

class HybridSurfaceApi {
  const HybridSurfaceApi(this.engine);
  final HybridSurfaceEngine engine;
  Future<HybridSurfacePlan> build(SurfacePlan plan) => engine.build(plan);
  HybridSurfacePlan get current =>
      engine.current ?? (throw StateError('No hybrid plan'));
  FreeformAdvice explain(String regionId) => engine.explainRegion(regionId);
  List<String> validate() => engine.validate();
  HybridSurfaceStatistics statistics() => engine.statistics();
}
