import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../models/surface_morph_models.dart';

class MorphValidator {
  const MorphValidator();
  MorphValidation validate(
    MorphSession session,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final patch = topology.patches
        .where((e) => e.id == session.targetPatch.id)
        .firstOrNull;
    final patchQuality = quality.patchQualities
        .where((e) => e.patch.id == session.targetPatch.id)
        .firstOrNull;
    final topologyValid = patch?.health == TopologyHealth.healthy;
    final boundariesValid =
        patch != null &&
        patch.boundaryIds.every(
          (id) => topology.boundaries
              .where((e) => e.id == id)
              .every((e) => e.health != TopologyHealth.invalid),
        );
    final qualityValid =
        patchQuality != null &&
        patchQuality.health != SurfaceQualityHealth.critical;
    final continuityValid = quality.continuity
        .where(
          (e) =>
              e.firstPatchId == session.targetPatch.id ||
              e.secondPatchId == session.targetPatch.id,
        )
        .every(
          (e) =>
              e.level != ContinuityLevel.g0 || session.tool == MorphTool.match,
        );
    final constraints = session.constraintGroups
        .expand((e) => e.constraints)
        .where((e) => e.enabled)
        .toList();
    final conflicts = <String>[
      for (final c in constraints)
        if ((c.type == SurfaceConstraintType.anchor ||
                c.type == SurfaceConstraintType.lockedBoundary) &&
            session.preview?.affectedBoundaries.contains(c.targetId) == true)
          'Locked morph target: ${c.targetId}',
    ];
    final errors = <String>[
      if (!topologyValid) 'Topology validation failed',
      if (!continuityValid) 'Continuity validation failed',
      if (!qualityValid) 'Surface quality validation failed',
      if (patch == null) 'Affected patch is missing',
      if (!boundariesValid) 'Affected boundary validation failed',
      if (session.anchors.isEmpty) 'Morph requires at least one anchor',
      ...conflicts,
    ];
    return MorphValidation(
      errors.isEmpty,
      topologyValid,
      continuityValid,
      qualityValid,
      patch != null,
      boundariesValid,
      List.unmodifiable(conflicts),
      List.unmodifiable(errors),
    );
  }
}
