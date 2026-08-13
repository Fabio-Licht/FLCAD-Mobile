import 'dart:math' as math;

import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../../geometric_recognition/recognizers/supported_recognizers.dart';

class CylinderProfessionalRecognizer extends FittedRecognizer {
  const CylinderProfessionalRecognizer();
  @override
  String get id => 'uers.cylinder.v1';
  @override
  PrimitiveType get type => PrimitiveType.cylinder;
  @override
  bool detect(RecognitionContext context) =>
      context.observation.points.length >= 6;
  @override
  RecognitionCandidate evaluate(RecognitionContext context) {
    final pca = statistics.pca(context.observation),
        center = Vector3(pca.mean[0], pca.mean[1], pca.mean[2]),
        axis = Vector3(
          pca.axes[0][0],
          pca.axes[0][1],
          pca.axes[0][2],
        ).normalized,
        distances = context.observation.points
            .map((p) => (p - center).cross(axis).length)
            .toList(),
        radius = _robustMean(distances),
        residuals = distances.map((d) => (d - radius).abs()).toList(),
        stats = fitStatistics(context, residuals);
    return RecognitionCandidate(
      id: '$id:${context.observation.regionFingerprint}',
      type: type,
      regionId: context.observation.regionId,
      parameters: {
        'origin': [center.x, center.y, center.z],
        'axis': [axis.x, axis.y, axis.z],
        'radius': radius,
      },
      statistics: stats,
      evidence: [
        RecognitionEvidence(
          'cylinder-radial-residual',
          'Distâncias ao eixo ajustadas com pesos robustos',
          id,
          stats.score,
        ),
      ],
      origin: id,
    );
  }
}

class ConeProfessionalRecognizer extends FittedRecognizer {
  const ConeProfessionalRecognizer();
  @override
  String get id => 'uers.cone.v1';
  @override
  PrimitiveType get type => PrimitiveType.cone;
  @override
  bool detect(RecognitionContext context) =>
      context.observation.points.length >= 7;
  @override
  RecognitionCandidate evaluate(RecognitionContext context) {
    final pca = statistics.pca(context.observation),
        center = Vector3(pca.mean[0], pca.mean[1], pca.mean[2]),
        axis = Vector3(
          pca.axes[0][0],
          pca.axes[0][1],
          pca.axes[0][2],
        ).normalized,
        samples = context.observation.points.map((p) {
          final delta = p - center,
              height = delta.dot(axis),
              radius = delta.cross(axis).length;
          return (height, radius);
        }).toList(),
        meanH =
            samples.map((e) => e.$1).reduce((a, b) => a + b) / samples.length,
        meanR =
            samples.map((e) => e.$2).reduce((a, b) => a + b) / samples.length,
        denominator = samples
            .map((e) => math.pow(e.$1 - meanH, 2))
            .reduce((a, b) => a + b),
        slope = denominator < 1e-14
            ? 0.0
            : samples
                      .map((e) => (e.$1 - meanH) * (e.$2 - meanR))
                      .reduce((a, b) => a + b) /
                  denominator,
        intercept = meanR - slope * meanH,
        residuals = samples
            .map((e) => (e.$2 - (intercept + slope * e.$1)).abs())
            .toList(),
        stats = fitStatistics(context, residuals),
        angle = math.atan(slope.abs());
    return RecognitionCandidate(
      id: '$id:${context.observation.regionFingerprint}',
      type: type,
      regionId: context.observation.regionId,
      parameters: {
        'origin': [center.x, center.y, center.z],
        'axis': [axis.x, axis.y, axis.z],
        'referenceRadius': intercept,
        'halfAngle': angle,
      },
      statistics: stats,
      evidence: [
        RecognitionEvidence(
          'cone-linear-radius',
          'Raio varia linearmente ao longo do eixo PCA',
          id,
          stats.score,
        ),
      ],
      origin: id,
    );
  }
}

class TorusProfessionalRecognizer extends FittedRecognizer {
  const TorusProfessionalRecognizer();
  @override
  String get id => 'uers.torus.v1';
  @override
  PrimitiveType get type => PrimitiveType.torus;
  @override
  bool detect(RecognitionContext context) =>
      context.observation.points.length >= 10;
  @override
  RecognitionCandidate evaluate(RecognitionContext context) {
    final pca = statistics.pca(context.observation),
        center = Vector3(pca.mean[0], pca.mean[1], pca.mean[2]),
        axis = Vector3(
          pca.axes[2][0],
          pca.axes[2][1],
          pca.axes[2][2],
        ).normalized,
        samples = context.observation.points.map((p) {
          final delta = p - center,
              axial = delta.dot(axis),
              radial = delta.cross(axis).length;
          return (radial, axial);
        }).toList(),
        major = _robustMean(samples.map((e) => e.$1).toList()),
        tubes = samples
            .map((e) => math.sqrt(math.pow(e.$1 - major, 2) + e.$2 * e.$2))
            .toList(),
        minor = _robustMean(tubes),
        residuals = tubes.map((e) => (e - minor).abs()).toList(),
        stats = fitStatistics(context, residuals);
    return RecognitionCandidate(
      id: '$id:${context.observation.regionFingerprint}',
      type: type,
      regionId: context.observation.regionId,
      parameters: {
        'center': [center.x, center.y, center.z],
        'axis': [axis.x, axis.y, axis.z],
        'majorRadius': major,
        'minorRadius': minor,
      },
      statistics: stats,
      evidence: [
        RecognitionEvidence(
          'torus-tube-residual',
          'Distância ao círculo gerador avaliada robustamente',
          id,
          stats.score,
        ),
      ],
      origin: id,
    );
  }
}

double _robustMean(List<double> values) {
  final sorted = [...values]..sort(),
      median = sorted[sorted.length ~/ 2],
      deviations = values.map((v) => (v - median).abs()).toList()..sort(),
      mad = deviations[deviations.length ~/ 2];
  final inliers = mad == 0
      ? values
      : values.where((v) => (v - median).abs() <= 3 * mad).toList();
  return inliers.reduce((a, b) => a + b) / inliers.length;
}
