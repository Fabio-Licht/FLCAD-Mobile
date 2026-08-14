import '../../surface_operations/models/surface_operation_models.dart';
import '../models/live_reconstruction_models.dart';

class AffectedObjectsCalculator {
  const AffectedObjectsCalculator();
  AffectedObjects calculate(
    SurfaceOperation operation,
    ReconstructionDependencyGraph graph,
  ) {
    final preview =
        operation.preview ??
        (throw StateError('Live reconstruction requires an operation preview'));
    final roots = {
      ...preview.affectedPatches,
      ...preview.affectedBoundaries,
      ...preview.affectedContinuity,
    };
    final impacted = graph.downstream(roots);
    Set<String> type(String value) =>
        impacted.where((id) => graph.nodes[id] == value).toSet();
    return AffectedObjects(
      regions: {operation.targetPatch.recognitionRegionId, ...type('region')},
      patches: type('patch'),
      boundaries: type('boundary'),
      continuity: type('continuity'),
      validation: type('validation'),
      analytics: type('analytics'),
      reflection: type('reflection'),
      zebra: type('zebra'),
      draft: type('draft'),
      heatMap: type('heatMap'),
    );
  }
}
