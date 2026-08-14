import '../../surface_continuity/models/surface_continuity_models.dart';
import '../models/live_reconstruction_models.dart';

class ReconstructionAdvisor {
  const ReconstructionAdvisor();
  List<ReconstructionAdvice> advise(
    AffectedObjects affected,
    SurfaceQualityReport quality,
  ) => [
    ReconstructionAdvice(
      'Modifying this patch affects ${affected.boundaries.length} boundaries.',
    ),
    if (affected.reflection.isNotEmpty)
      const ReconstructionAdvice(
        'Reflection must be recalculated and may be degraded.',
      ),
    if (quality.continuity.any(
      (e) =>
          affected.continuity.contains(e.id) && e.level == ContinuityLevel.g2,
    ))
      const ReconstructionAdvice('G2 continuity may be lost.'),
    if (affected.validation.isNotEmpty)
      const ReconstructionAdvice(
        'Validation must be recalculated for affected objects.',
      ),
  ];
}
