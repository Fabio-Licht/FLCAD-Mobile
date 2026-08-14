import '../../surface_continuity/models/surface_continuity_models.dart';
import '../models/surface_morph_models.dart';

class MorphAdvisor {
  const MorphAdvisor();
  List<MorphAdvice> advise(
    MorphSession session,
    SurfaceQualityReport quality,
  ) => [
    if (session.anchors.length < 2)
      const MorphAdvice('This region has limited anchoring.'),
    if (quality.continuity.any(
      (e) =>
          (e.firstPatchId == session.targetPatch.id ||
              e.secondPatchId == session.targetPatch.id) &&
          e.level == ContinuityLevel.g2,
    ))
      const MorphAdvice('The deformation may degrade G2 continuity.'),
    if (session.targetPatch.boundaryIds.isNotEmpty &&
        session.anchors.every((e) => e.type != AnchorType.boundary))
      const MorphAdvice('Consider adding an Anchor to this Boundary.'),
  ];
}
