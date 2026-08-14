import 'dart:math' as math;

import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_kernel/linear_algebra/linear_algebra.dart';
import '../../geometric_kernel/services/fitting_engine.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../models/surface_recognition_models.dart';

class PrimitiveClassifier {
  const PrimitiveClassifier();

  SurfaceClassification classify(SurfaceRegion region, MeshSurfaceData mesh) {
    final points = region.vertexIndices.map((i) => mesh.vertices[i]).toList();
    if (points.length < 3) {
      return _unknown(region, 'Região insuficiente para ajuste.');
    }
    final scale = _scale(region.bounds), candidates = <_Fit>[];
    final plane = const FittingEngine().fitPlane(points);
    candidates.add(
      _Fit(
        PrimitiveType.plane,
        plane.rmsError / scale,
        {
          'origin': plane.geometry.origin.toJson(),
          'normal': plane.geometry.normal.toJson(),
        },
        [
          'PCA/least-squares',
          'desvio ortogonal RMS',
          'continuidade topológica',
        ],
      ),
    );
    if (points.length >= 4) {
      try {
        final sphere = const FittingEngine().fitSphere(points);
        candidates.add(
          _Fit(
            PrimitiveType.sphere,
            sphere.rmsError / scale,
            {
              'center': sphere.geometry.center.toJson(),
              'radius': sphere.geometry.radius,
            },
            [
              'least-squares esférico',
              'coerência radial',
              'cobertura da região',
            ],
          ),
        );
      } catch (_) {}
    }
    if (points.length >= 6) {
      final radial = _radialFits(points, region.averageNormal, scale);
      candidates.addAll(radial);
    }
    candidates.sort((a, b) => a.error.compareTo(b.error));
    final winner = candidates.first;
    final separation = candidates.length > 1
        ? ((candidates[1].error - winner.error) /
                  math.max(candidates[1].error, 1e-12))
              .clamp(0.0, 1.0)
        : 0.0;
    final fitScore = (1 / (1 + winner.error * 80)).clamp(0.0, 1.0);
    final continuity = region.confidence;
    final confidence = (fitScore * .60 + continuity * .25 + separation * .15)
        .clamp(0.0, 1.0);
    final accepted = winner.error < .035 && confidence >= .48;
    final type = accepted
        ? winner.type
        : (region.triangleIndices.length >= 8
              ? PrimitiveType.freeform
              : PrimitiveType.unknown);
    final finalConfidence = accepted
        ? confidence
        : math.max(.2, confidence * .65);
    return SurfaceClassification(
      region: region,
      type: type,
      confidence: finalConfidence,
      quality: fitScore,
      parameters: accepted ? winner.parameters : const {},
      evidence: [
        ...winner.evidence,
        'erro normalizado=${winner.error.toStringAsPrecision(5)}',
        'separação estatística=${separation.toStringAsPrecision(4)}',
      ],
      reason: accepted
          ? '${winner.type.name} venceu a competição de ajustes por RMS, continuidade e estabilidade.'
          : 'Nenhum ajuste primitivo atingiu simultaneamente erro e confiança mínimos.',
      rms: winner.error * scale,
    );
  }

  List<_Fit> _radialFits(List<Vector3> points, Vector3 fallback, double scale) {
    final pca = const LinearAlgebra().principalComponents(
      points.map((p) => [p.x, p.y, p.z]).toList(),
    );
    final center = _mean(points);
    final axes = [
      for (final a in pca.axes) Vector3(a[0], a[1], a[2]).normalized,
    ];
    final result = <_Fit>[];
    for (final axis in axes) {
      final basisU = axis
          .cross(
            axis.z.abs() < .9 ? const Vector3(0, 0, 1) : const Vector3(0, 1, 0),
          )
          .normalized;
      final basisV = axis.cross(basisU).normalized;
      final coordinates = points.map((p) {
        final d = p - center;
        return (d.dot(basisU), d.dot(basisV), d.dot(axis));
      }).toList();
      try {
        final m = DenseMatrix(
          coordinates.map((p) => [2 * p.$1, 2 * p.$2, 1.0]).toList(),
        );
        final y = coordinates.map((p) => p.$1 * p.$1 + p.$2 * p.$2).toList();
        final solution = const LinearAlgebra().leastSquares(m, y);
        final cx = solution[0], cy = solution[1];
        final radii = coordinates
            .map(
              (p) => math.sqrt(math.pow(p.$1 - cx, 2) + math.pow(p.$2 - cy, 2)),
            )
            .toList();
        final radius = radii.reduce((a, b) => a + b) / radii.length;
        final cylinderError = _rms(radii.map((r) => r - radius)) / scale;
        final origin = center + basisU * cx + basisV * cy;
        result.add(
          _Fit(
            PrimitiveType.cylinder,
            cylinderError,
            {
              'axis': axis.toJson(),
              'origin': origin.toJson(),
              'radius': radius,
            },
            [
              'ajuste circular transversal',
              'estabilidade do eixo PCA',
              'resíduo radial RMS',
            ],
          ),
        );
        final zMean =
            coordinates.map((p) => p.$3).reduce((a, b) => a + b) /
            coordinates.length;
        final zVar =
            coordinates.fold<double>(
              0,
              (s, p) => s + math.pow(p.$3 - zMean, 2),
            ) /
            coordinates.length;
        if (zVar > 1e-18) {
          final rMean = radius;
          final slope =
              coordinates.asMap().entries.fold<double>(
                0,
                (s, e) => s + (e.value.$3 - zMean) * (radii[e.key] - rMean),
              ) /
              coordinates.fold<double>(
                0,
                (s, p) => s + math.pow(p.$3 - zMean, 2),
              );
          final intercept = rMean - slope * zMean;
          final coneError =
              _rms(
                coordinates.asMap().entries.map(
                  (e) => radii[e.key] - (slope * e.value.$3 + intercept),
                ),
              ) /
              scale;
          final coneAngle = math.atan(slope.abs());
          if (coneAngle >= .01 && coneAngle <= math.pi / 2 - .01) {
            result.add(
              _Fit(
                PrimitiveType.cone,
                coneError,
                {
                  'axis': axis.toJson(),
                  'apex':
                      (center -
                              axis *
                                  (intercept /
                                      slope.abs().clamp(
                                        1e-12,
                                        double.infinity,
                                      )))
                          .toJson(),
                  'angle': coneAngle,
                },
                ['regressão raio-altura', 'eixo PCA', 'resíduo cônico RMS'],
              ),
            );
          }
        }
        final major = radius;
        final tubeDistances = coordinates
            .map(
              (p) => math.sqrt(
                math.pow(math.sqrt(p.$1 * p.$1 + p.$2 * p.$2) - major, 2) +
                    p.$3 * p.$3,
              ),
            )
            .toList();
        final tube =
            tubeDistances.reduce((a, b) => a + b) / tubeDistances.length;
        result.add(
          _Fit(
            PrimitiveType.torus,
            _rms(tubeDistances.map((r) => r - tube)) / scale,
            {
              'axis': axis.toJson(),
              'center': center.toJson(),
              'majorRadius': major,
              'minorRadius': tube,
            },
            [
              'distância ao círculo diretor',
              'eixo PCA',
              'resíduo toroidal RMS',
            ],
          ),
        );
      } catch (_) {}
    }
    return result;
  }

  SurfaceClassification _unknown(SurfaceRegion r, String reason) =>
      SurfaceClassification(
        region: r,
        type: PrimitiveType.unknown,
        confidence: 0,
        quality: 0,
        parameters: const {},
        evidence: const [],
        reason: reason,
        rms: double.infinity,
      );
  Vector3 _mean(List<Vector3> p) =>
      p.reduce((a, b) => a + b) / p.length.toDouble();
  double _rms(Iterable<double> v) {
    final x = v.toList();
    return math.sqrt(x.fold<double>(0, (s, e) => s + e * e) / x.length);
  }

  double _scale(dynamic b) => math.max(
    math.sqrt(
      math.pow(b.maxX - b.minX, 2) +
          math.pow(b.maxY - b.minY, 2) +
          math.pow(b.maxZ - b.minZ, 2),
    ),
    1e-12,
  );
}

class _Fit {
  const _Fit(this.type, this.error, this.parameters, this.evidence);
  final PrimitiveType type;
  final double error;
  final Map<String, dynamic> parameters;
  final List<String> evidence;
}
