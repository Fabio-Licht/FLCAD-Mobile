import 'dart:math' as math;
import '../../cad_kernel/io/kernel_io_models.dart';
import '../../geometric_kernel/geometry/vectors.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../advisor/quality_advisor.dart';
import '../integration/surface_continuity_integration.dart';
import '../models/surface_continuity_models.dart';
import '../repository/surface_continuity_repository.dart';
import '../runtime/surface_continuity_runtime.dart';
import '../validation/surface_quality_validation.dart';

class SurfaceContinuitySettings {
  const SurfaceContinuitySettings({
    this.draftDirection = const [0, 0, 1],
    this.samples = 100,
    this.zebraDensity = 12,
    this.zebraContrast = 1,
  });
  final List<double> draftDirection;
  final int samples;
  final double zebraDensity, zebraContrast;
}

class SurfaceContinuityEngine {
  SurfaceContinuityEngine({
    required this.kernel,
    required this.repository,
    this.integration,
    this.settings = const SurfaceContinuitySettings(),
  });
  final SurfaceQualityKernelAPI kernel;
  final SurfaceContinuityRepository repository;
  final SurfaceContinuityIntegration? integration;
  final SurfaceContinuitySettings settings;
  final advisor = const SurfaceQualityAdvisor(),
      validation = const SurfaceQualityValidation();
  Future<SurfaceQualityReport> analyze(SurfaceTopologyReport topology) async {
    await SurfaceContinuityRuntime.instance.initialize();
    final watch = Stopwatch()..start(),
        native = <String, Map<String, dynamic>>{};
    for (final patch in topology.patches) {
      native[patch.id] = await kernel.inspectSurfaceQuality(
        patch.surface.handle!,
        draftDirection: settings.draftDirection,
        samples: settings.samples,
      );
    }
    final continuity = <ContinuityAssessment>[];
    final seen = <String>{};
    for (final patch in topology.patches) {
      if (patch.adjacentPatchIds.isEmpty) {
        continuity.add(
          ContinuityAssessment(
            id: 'continuity:${patch.id}:na',
            firstPatchId: patch.id,
            secondPatchId: patch.id,
            discontinuity: 0,
            angle: 0,
            maximumError: 0,
            meanError: 0,
            rms: 0,
            effective: 0,
            level: ContinuityLevel.notApplicable,
            classification: 'No shared patch boundary',
          ),
        );
      }
      for (final neighborId in patch.adjacentPatchIds) {
        final key = [patch.id, neighborId]..sort();
        if (!seen.add(key.join('|'))) continue;
        final other = topology.patches.firstWhere((e) => e.id == neighborId),
            a = native[patch.id]!,
            b = native[other.id]!,
            na = Vector3.fromJson(
              (a['averageNormal'] as List).cast<dynamic>(),
            ).normalized,
            nb = Vector3.fromJson(
              (b['averageNormal'] as List).cast<dynamic>(),
            ).normalized,
            angle = math.acos(na.dot(nb).abs().clamp(-1.0, 1.0)),
            curvature =
                ((a['meanCurvature'] as num).toDouble() -
                        (b['meanCurvature'] as num).toDouble())
                    .abs(),
            intersection = topology.intersections
                .where(
                  (e) =>
                      (e.firstSurfaceId == patch.surface.id &&
                          e.secondSurfaceId == other.surface.id) ||
                      (e.secondSurfaceId == patch.surface.id &&
                          e.firstSurfaceId == other.surface.id),
                )
                .firstOrNull,
            gap = intersection == null ? 1.0 : 0.0,
            level = gap > 1e-6
                ? ContinuityLevel.notApplicable
                : angle < 1e-3 && curvature < 1e-4
                ? ContinuityLevel.g2
                : angle < math.pi / 180
                ? ContinuityLevel.g1
                : ContinuityLevel.g0,
            effective = (1 / (1 + gap + angle + curvature)).clamp(0.0, 1.0);
        continuity.add(
          ContinuityAssessment(
            id: 'continuity:${key.join(':')}',
            firstPatchId: patch.id,
            secondPatchId: other.id,
            discontinuity: gap,
            angle: angle,
            maximumError: math.max(gap, math.max(angle, curvature)),
            meanError: (gap + angle + curvature) / 3,
            rms: math.sqrt(
              (gap * gap + angle * angle + curvature * curvature) / 3,
            ),
            effective: effective,
            level: level,
            classification: 'Native position, normal and curvature comparison',
          ),
        );
      }
    }
    final qualities = <PatchQuality>[];
    for (final patch in topology.patches) {
      final q = native[patch.id]!,
          z = Map<String, dynamic>.from(q['zebra'] as Map),
          d = Map<String, dynamic>.from(q['draft'] as Map),
          mean = (q['meanCurvature'] as num).toDouble(),
          stability = (q['curvatureStability'] as num).toDouble(),
          reflection = (q['reflectionScore'] as num).toDouble(),
          draftTotal =
              (d['negative'] as int) +
              (d['critical'] as int) +
              (d['approved'] as int),
          draftScore = draftTotal == 0
              ? 0.0
              : ((d['approved'] as int) / draftTotal),
          related = continuity
              .where(
                (e) =>
                    e.firstPatchId == patch.id || e.secondPatchId == patch.id,
              )
              .toList(),
          applicable = related
              .where((e) => e.level != ContinuityLevel.notApplicable)
              .toList(),
          continuityScore = applicable.isEmpty
              ? 0.5
              : applicable.fold<double>(0, (s, e) => s + e.effective) /
                    applicable.length,
          topologyScore = patch.health == TopologyHealth.healthy ? 1.0 : 0.3,
          curvatureScore = stability.clamp(0.0, 1.0).toDouble(),
          overall =
              (continuityScore * .2 +
                      curvatureScore * .2 +
                      reflection * .15 +
                      draftScore * .15 +
                      topologyScore * .1 +
                      patch.surface.confidence * .2)
                  .clamp(0.0, 1.0)
                  .toDouble();
      qualities.add(
        PatchQuality(
          patch: patch,
          curvature: CurvatureAnalysis(
            minimum: (q['minimumCurvature'] as num).toDouble(),
            maximum: (q['maximumCurvature'] as num).toDouble(),
            averageMinimum: (q['averageMinimumCurvature'] as num).toDouble(),
            averageMaximum: (q['averageMaximumCurvature'] as num).toDouble(),
            mean: mean,
            gaussian: (q['gaussianCurvature'] as num).toDouble(),
            gradient: (q['curvatureGradient'] as num).toDouble(),
            stability: stability,
            equivalentRadius: mean.abs() < 1e-12
                ? double.infinity
                : 1 / mean.abs(),
          ),
          reflection: ReflectionAnalysis(
            lines: [
              (z['horizontal'] as num).toDouble(),
              (z['vertical'] as num).toDouble(),
              (z['radial'] as num).toDouble(),
            ],
            environment: reflection,
            flow: stability,
            quality: reflection,
          ),
          zebra: ZebraAnalysis(
            horizontal: (z['horizontal'] as num).toDouble(),
            vertical: (z['vertical'] as num).toDouble(),
            radial: (z['radial'] as num).toDouble(),
            free: (z['free'] as num).toDouble(),
            density: settings.zebraDensity,
            contrast: settings.zebraContrast,
          ),
          draft: DraftAnalysis(
            direction: settings.draftDirection,
            minimumAngle: (d['minimumAngle'] as num).toDouble(),
            maximumAngle: (d['maximumAngle'] as num).toDouble(),
            negative: d['negative'] as int,
            critical: d['critical'] as int,
            approved: d['approved'] as int,
          ),
          continuityScore: continuityScore,
          curvatureScore: curvatureScore,
          reflectionScore: reflection,
          draftScore: draftScore,
          topologyScore: topologyScore,
          recognitionConfidence: patch.confidence,
          surfaceConfidence: patch.surface.confidence,
          overall: overall,
          health: _health(overall),
        ),
      );
    }
    final nodes = {
          for (final q in qualities)
            q.patch.id: {
              'continuity': q.continuityScore,
              'curvature': q.curvature.toJson(),
              'reflection': q.reflection.quality,
              'draft': q.draftScore,
              'health': q.health.name,
            },
        },
        edges = {
          for (final q in qualities)
            q.patch.id: <String>{...q.patch.adjacentPatchIds},
        },
        distribution = {
          for (final level in ContinuityLevel.values)
            level: continuity.where((e) => e.level == level).length,
        };
    double avg(double Function(PatchQuality) f) => qualities.isEmpty
        ? 0
        : qualities.fold<double>(0, (s, e) => s + f(e)) / qualities.length;
    watch.stop();
    final analytics = SurfaceQualityAnalytics(
          elapsed: watch.elapsed,
          patchCount: qualities.length,
          continuityDistribution: distribution,
          averageCurvature: avg((e) => e.curvature.mean),
          reflectionScore: avg((e) => e.reflectionScore),
          draftScore: avg((e) => e.draftScore),
          qualityScore: avg((e) => e.overall),
        ),
        report = SurfaceQualityReport(
          id: 'surface-quality:${IdGenerator.generate()}',
          topologyReportId: topology.id,
          patchQualities: qualities,
          continuity: continuity,
          graph: ContinuityGraph(nodes, edges),
          analytics: analytics,
          advice: advisor.advise(qualities, continuity),
          createdAt: DateTime.now().toUtc(),
        ),
        errors = validation.validate(report);
    if (errors.isNotEmpty) throw StateError(errors.join('; '));
    repository.save(report);
    integration?.onQualityAnalyzed(report);
    return report;
  }

  SurfaceQualityHealth _health(double v) => switch (v) {
    >= .9 => SurfaceQualityHealth.excellent,
    >= .75 => SurfaceQualityHealth.good,
    >= .6 => SurfaceQualityHealth.acceptable,
    >= .4 => SurfaceQualityHealth.warning,
    _ => SurfaceQualityHealth.critical,
  };
}
