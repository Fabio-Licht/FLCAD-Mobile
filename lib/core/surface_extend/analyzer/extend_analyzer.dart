import 'dart:math' as math;
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../models/surface_extend_models.dart';

class ExtendAnalyzer {
  const ExtendAnalyzer();
  ExtendAnalysis analyze(ExtendSession session, SurfaceQualityReport quality) {
    final q = quality.patchQualities.firstWhere(
          (e) => e.patch.id == session.patch.id,
        ),
        distance = (session.parameters['distance'] as num?)?.toDouble() ?? 0,
        angle = (session.parameters['angle'] as num?)?.toDouble() ?? 0,
        direction =
            ((session.parameters['vector'] as List?)
                ?.cast<num>()
                .map((e) => e.toDouble())
                .toList() ??
            const [0.0, 0.0, 1.0]),
        bounds = session.patch.surface.bounds,
        diagonal = math.sqrt(
          math.pow(bounds.maxX - bounds.minX, 2) +
              math.pow(bounds.maxY - bounds.minY, 2) +
              math.pow(bounds.maxZ - bounds.minZ, 2),
        ),
        tension = (distance.abs() / (diagonal + 1e-9)).clamp(0.0, 1.0),
        twist = ((angle.abs() / 180) + tension * .25).clamp(0.0, 1.0),
        reflection = (q.reflectionScore * (1 - twist * .3)).clamp(0.0, 1.0),
        zebra =
            (((q.zebra.horizontal + q.zebra.vertical + q.zebra.radial) / 3) *
                    (1 - twist * .25))
                .clamp(0.0, 1.0),
        estimated = (q.overall * .6 + reflection * .2 + zebra * .2).clamp(
          0.0,
          1.0,
        );
    return ExtendAnalysis(
      distance: distance,
      angle: angle,
      direction: direction,
      affectedPatches: [session.patch.id, ...session.patch.adjacentPatchIds],
      affectedBoundaries: [session.boundaryId],
      predictedContinuity: session.type == ExtendType.curvatureG2
          ? 'G2'
          : session.type == ExtendType.tangentG1
          ? 'G1'
          : 'Preserve current',
      reflectionScore: reflection.toDouble(),
      zebraScore: zebra.toDouble(),
      tension: tension.toDouble(),
      twistRisk: twist.toDouble(),
      estimatedQuality: estimated.toDouble(),
      selfIntersectionRisk: (tension * twist).clamp(0.0, 1.0).toDouble(),
    );
  }

  ExtendType suggest(ExtendSession session) {
    if (session.manufacturingIntent.isNotEmpty) return ExtendType.manufacturing;
    if (session.patch.surface.primitiveType.name == 'cylinder') {
      return ExtendType.curvatureG2;
    }
    if (session.patch.surface.primitiveType.name == 'plane') {
      return ExtendType.tangentG1;
    }
    return ((session.parameters['distance'] as num?)?.toDouble() ?? 0).abs() <
            10
        ? ExtendType.distance
        : ExtendType.vector;
  }
}
