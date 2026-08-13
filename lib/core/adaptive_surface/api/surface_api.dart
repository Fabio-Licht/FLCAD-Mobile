import '../advisor/surface_advisor.dart';
import '../builders/surface_builder.dart';
import '../engine/adaptive_surface_engine.dart';
import '../graph/surface_graph.dart';
import '../models/adaptive_surface.dart';
import '../network/surface_network.dart';
import '../optimization/global_surface_optimizer.dart';
import '../repair/surface_repair_engine.dart';

class SurfaceApi {
  SurfaceApi({AdaptiveSurfaceEngine? engine})
    : _engine = engine ?? AdaptiveSurfaceEngine();
  final AdaptiveSurfaceEngine _engine;
  Future<AdaptiveSurface> create({
    required String projectId,
    required String name,
    required SurfaceBuildRequest request,
    SurfaceMode mode = SurfaceMode.live,
    SurfaceStage stage = SurfaceStage.alpha,
    ManufacturingProcess manufacturingProcess = ManufacturingProcess.unknown,
    Map<String, EngineeringNodeKind> sourceKinds = const {},
  }) => _engine.create(
    projectId: projectId,
    name: name,
    request: request,
    mode: mode,
    stage: stage,
    manufacturingProcess: manufacturingProcess,
    sourceKinds: sourceKinds,
  );
  Future<List<AdaptiveSurface>> list(String id) => _engine.repository.load(id);
  Future<AdaptiveSurface> rebuild(AdaptiveSurface s, SurfaceBuildRequest r) =>
      _engine.rebuild(s, r);
  Future<AdaptiveSurface> refine(AdaptiveSurface s, SurfaceStage stage) =>
      _engine.refine(s, stage);
  Future<AdaptiveSurface> repair(
    AdaptiveSurface s,
    Set<SurfaceRepairAction> actions,
  ) => _engine.repair(s, actions);
  Future<bool> validate(AdaptiveSurface s) => _engine.validate(s);
  Future<void> delete(AdaptiveSurface s) => _engine.delete(s);
  Future<void> restore(AdaptiveSurface s) => _engine.restore(s);
  Future<List<SurfaceAdvice>> advise(SurfaceBuildRequest r) =>
      _engine.advisor.advise(r);
  Future<SurfaceGraph> graph(String id) => _engine.graphFor(id);
  Future<GlobalOptimizationResult> optimizeNetwork(SurfaceNetwork network) =>
      _engine.optimizeNetwork(network);
}
