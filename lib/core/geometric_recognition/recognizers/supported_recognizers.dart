import 'dart:math' as math;

import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_kernel/linear_algebra/linear_algebra.dart';
import '../../geometric_kernel/services/fitting_engine.dart';
import '../models/recognition_models.dart';
import '../statistics/statistical_engine.dart';
import 'universal_recognizer.dart';

abstract class FittedRecognizer implements UniversalRecognizer {
  const FittedRecognizer();
  final statistics = const RecognitionStatisticalEngine();
  double scale(RecognitionContext context) {
    final p = context.observation.points;
    if (p.isEmpty) return 1;
    var minX = p.first.x,
        minY = p.first.y,
        minZ = p.first.z,
        maxX = minX,
        maxY = minY,
        maxZ = minZ;
    for (final value in p.skip(1)) {
      minX = math.min(minX, value.x);
      minY = math.min(minY, value.y);
      minZ = math.min(minZ, value.z);
      maxX = math.max(maxX, value.x);
      maxY = math.max(maxY, value.y);
      maxZ = math.max(maxZ, value.z);
    }
    return math.max(
      Vector3(maxX - minX, maxY - minY, maxZ - minZ).length,
      1e-12,
    );
  }

  FitStatistics fitStatistics(
    RecognitionContext context,
    List<double> residuals,
  ) {
    final analysis = statistics.residuals(residuals),
        normalized = analysis.rms / scale(context),
        quality = 1 / (1 + normalized),
        stability = 1 / (1 + analysis.maximum / scale(context));
    return FitStatistics(
      rms: analysis.rms,
      maximum: analysis.maximum,
      mean: analysis.mean,
      coverage: analysis.inlierRatio,
      stability: stability,
      score: quality * analysis.inlierRatio * stability,
      confidenceInterval: analysis.confidenceInterval,
    );
  }

  @override
  double confidence(
    RecognitionContext context,
    RecognitionCandidate candidate,
  ) => candidate.statistics.score;
  @override
  RecognitionCandidate refine(
    RecognitionContext context,
    RecognitionCandidate candidate,
  ) => candidate.copyWith(status: RecognitionStatus.refined);
  @override
  bool validate(RecognitionContext context, RecognitionCandidate candidate) =>
      candidate.statistics.rms.isFinite &&
      candidate.statistics.coverage > 0 &&
      candidate.parameters.values.every(
        (value) => value is! double || value.isFinite,
      );
  @override
  RecognitionExplanation explain(
    RecognitionContext context,
    RecognitionCandidate candidate,
    List<RecognitionCandidate> alternatives,
  ) => RecognitionExplanation(
    why: '${candidate.type.name} obteve o melhor ajuste estatístico validado.',
    evidence: candidate.evidence,
    regions: [candidate.regionId],
    parameters: candidate.parameters,
    losingCandidates: alternatives
        .map((e) => '${e.type.name}: ${e.statistics.score.toStringAsFixed(4)}')
        .toList(),
    score: candidate.statistics.score,
    confidence: confidence(context, candidate),
  );
}

class PlaneRecognizer extends FittedRecognizer {
  const PlaneRecognizer();
  @override
  String get id => 'urf.plane.v1';
  @override
  PrimitiveType get type => PrimitiveType.plane;
  @override
  bool detect(RecognitionContext context) =>
      context.observation.points.length >= 3;
  @override
  RecognitionCandidate evaluate(RecognitionContext context) {
    final fit = const FittingEngine().fitPlane(context.observation.points),
        geometry = fit.geometry,
        residuals = context.observation.points
            .map((p) => geometry.signedDistance(p).abs())
            .toList(),
        stats = fitStatistics(context, residuals);
    return RecognitionCandidate(
      id: '$id:${context.observation.regionFingerprint}',
      type: type,
      regionId: context.observation.regionId,
      parameters: {
        'origin': [geometry.origin.x, geometry.origin.y, geometry.origin.z],
        'normal': [geometry.normal.x, geometry.normal.y, geometry.normal.z],
      },
      statistics: stats,
      evidence: [
        RecognitionEvidence(
          'plane-residual',
          'Distâncias ortogonais avaliadas por PCA/least squares',
          'Geometric Kernel',
          1 - stats.rms / scale(context),
        ),
      ],
      origin: id,
    );
  }
}

class SphereRecognizer extends FittedRecognizer {
  const SphereRecognizer();
  @override
  String get id => 'urf.sphere.v1';
  @override
  PrimitiveType get type => PrimitiveType.sphere;
  @override
  bool detect(RecognitionContext context) =>
      context.observation.points.length >= 4;
  @override
  RecognitionCandidate evaluate(RecognitionContext context) {
    final points = context.observation.points,
        anchor = points.first,
        matrix = DenseMatrix(
          points
              .skip(1)
              .map(
                (point) => [
                  2 * (point.x - anchor.x),
                  2 * (point.y - anchor.y),
                  2 * (point.z - anchor.z),
                ],
              )
              .toList(),
        ),
        target = points
            .skip(1)
            .map((point) => point.lengthSquared - anchor.lengthSquared)
            .toList(),
        solution = const LinearAlgebra().leastSquares(matrix, target),
        center = Vector3(solution[0], solution[1], solution[2]),
        radii = points.map(center.distanceTo).toList(),
        radius = radii.reduce((a, b) => a + b) / radii.length,
        residuals = points
            .map((p) => (center.distanceTo(p) - radius).abs())
            .toList(),
        stats = fitStatistics(context, residuals);
    return RecognitionCandidate(
      id: '$id:${context.observation.regionFingerprint}',
      type: type,
      regionId: context.observation.regionId,
      parameters: {
        'center': [center.x, center.y, center.z],
        'radius': radius,
      },
      statistics: stats,
      evidence: [
        RecognitionEvidence(
          'sphere-residual',
          'Variação radial avaliada por least squares',
          'Geometric Kernel',
          1 - stats.rms / scale(context),
        ),
      ],
      origin: id,
    );
  }
}

class UnsupportedPrimitiveRecognizer implements UniversalRecognizer {
  const UnsupportedPrimitiveRecognizer(this.type);
  @override
  final PrimitiveType type;
  @override
  String get id => 'urf.${type.name}.contract';
  @override
  bool detect(RecognitionContext context) => false;
  @override
  RecognitionCandidate evaluate(RecognitionContext context) =>
      throw UnsupportedError('${type.name} recognizer is a contract only');
  @override
  RecognitionCandidate refine(
    RecognitionContext context,
    RecognitionCandidate candidate,
  ) => candidate;
  @override
  bool validate(RecognitionContext context, RecognitionCandidate candidate) =>
      false;
  @override
  RecognitionExplanation explain(
    RecognitionContext context,
    RecognitionCandidate candidate,
    List<RecognitionCandidate> alternatives,
  ) => throw UnsupportedError('${type.name} recognizer is a contract only');
  @override
  double confidence(
    RecognitionContext context,
    RecognitionCandidate candidate,
  ) => 0;
}
