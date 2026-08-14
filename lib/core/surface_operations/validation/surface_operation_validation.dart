import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../constraints/surface_constraint_solver.dart';
import '../models/surface_operation_models.dart';

class SurfaceOperationValidator {
  const SurfaceOperationValidator(this.solver);
  final SurfaceConstraintSolver solver;
  SurfaceOperationValidation validate(
    SurfaceOperation operation,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final solution = solver.solve(operation);
    final patch = topology.patches
        .where((e) => e.id == operation.targetPatch.id)
        .firstOrNull;
    final patchQuality = quality.patchQualities
        .where((e) => e.patch.id == operation.targetPatch.id)
        .firstOrNull;
    final topologyValid =
        patch != null && patch.health != TopologyHealth.invalid;
    final boundariesValid =
        patch != null &&
        patch.boundaryIds.every(
          (id) => topology.boundaries
              .where((e) => e.id == id)
              .every((e) => e.health != TopologyHealth.invalid),
        );
    final patchValid = patch?.health == TopologyHealth.healthy;
    final qualityValid =
        patchQuality != null &&
        patchQuality.health != SurfaceQualityHealth.critical;
    final continuityValid = quality.continuity
        .where(
          (e) =>
              e.firstPatchId == operation.targetPatch.id ||
              e.secondPatchId == operation.targetPatch.id,
        )
        .every(
          (e) =>
              e.level != ContinuityLevel.g0 ||
              operation.type == SurfaceOperationType.matchSurface,
        );
    final errors = <String>[
      if (!topologyValid) 'Topology validation failed',
      if (!continuityValid) 'Continuity validation failed',
      if (!boundariesValid) 'Boundary health validation failed',
      if (!patchValid) 'Patch health validation failed',
      if (!qualityValid) 'Surface quality validation failed',
      ...solution.conflicts,
    ];
    return SurfaceOperationValidation(
      valid: errors.isEmpty,
      topology: topologyValid,
      continuity: continuityValid,
      boundaryHealth: boundariesValid,
      patchHealth: patchValid,
      surfaceQuality: qualityValid,
      constraintConflicts: solution.conflicts,
      errors: List.unmodifiable(errors),
    );
  }
}
