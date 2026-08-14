import '../../surface_continuity/models/surface_continuity_models.dart';
import '../models/surface_operation_models.dart';

class SurfaceOperationAdvisor {
  const SurfaceOperationAdvisor();
  List<SurfaceOperationAdvice> advise(
    SurfaceOperation operation,
    SurfaceQualityReport quality,
  ) => [
    for (final conflict
        in operation.validation?.constraintConflicts ?? const <String>[])
      SurfaceOperationAdvice(
        operation.id,
        conflict,
        'Release the conflicting anchor or lock before commit.',
      ),
    if (quality.continuity.any(
      (e) =>
          (e.firstPatchId == operation.targetPatch.id ||
              e.secondPatchId == operation.targetPatch.id) &&
          e.level == ContinuityLevel.g2,
    ))
      SurfaceOperationAdvice(
        operation.id,
        'The target participates in G2 continuity.',
        'Review possible continuity degradation before commit.',
      ),
    if (operation.validation?.topology == false)
      SurfaceOperationAdvice(
        operation.id,
        'Topology conflict detected.',
        'Inspect all affected patches and boundaries.',
      ),
  ];
}
