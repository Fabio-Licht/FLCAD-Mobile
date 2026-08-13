import 'dart:math' as math;

import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../models/professional_recognition_models.dart';

class TopologyRecognitionEngine {
  const TopologyRecognitionEngine();
  List<TopologicalRelation> analyze(List<ProfessionalPrimitive> primitives) {
    final relations = <TopologicalRelation>[];
    for (var i = 0; i < primitives.length; i++) {
      for (var j = i + 1; j < primitives.length; j++) {
        final a = primitives[i].recognition.winner,
            b = primitives[j].recognition.winner;
        final axisA = _direction(a), axisB = _direction(b);
        if (axisA != null && axisB != null) {
          final dot = axisA.normalized.dot(axisB.normalized).abs().clamp(0, 1),
              parallelConfidence = math.pow(dot, 4).toDouble(),
              perpendicularConfidence = math.pow(1 - dot, 4).toDouble();
          if (parallelConfidence >= .8) {
            final origins = (_origin(a), _origin(b)),
                separation = origins.$1 == null || origins.$2 == null
                    ? double.infinity
                    : (origins.$2! - origins.$1!).cross(axisA).length,
                scale = math.max(_radius(a) ?? 1, _radius(b) ?? 1),
                coaxial = 1 / (1 + separation / scale);
            relations.add(
              _relation(
                a,
                b,
                coaxial >= .8
                    ? TopologicalRelationType.coaxial
                    : TopologicalRelationType.parallel,
                parallelConfidence * coaxial,
                {'axisDot': dot, 'separation': separation},
              ),
            );
          } else if (perpendicularConfidence >= .8) {
            relations.add(
              _relation(
                a,
                b,
                TopologicalRelationType.perpendicular,
                perpendicularConfidence,
                {'axisDot': dot},
              ),
            );
          }
        }
        if (a.type == PrimitiveType.sphere && b.type == PrimitiveType.sphere) {
          final ca = _origin(a), cb = _origin(b);
          if (ca != null && cb != null) {
            final distance = ca.distanceTo(cb),
                scale = math.max(_radius(a) ?? 1, _radius(b) ?? 1),
                confidence = 1 / (1 + distance / scale);
            if (confidence >= .8) {
              relations.add(
                _relation(
                  a,
                  b,
                  TopologicalRelationType.concentric,
                  confidence,
                  {'centerDistance': distance},
                ),
              );
            }
          }
        }
      }
    }
    return relations;
  }

  TopologicalRelation _relation(
    RecognitionCandidate a,
    RecognitionCandidate b,
    TopologicalRelationType type,
    double confidence,
    Map<String, dynamic> parameters,
  ) => TopologicalRelation(
    id: 'relation:${a.id}:${b.id}:${type.name}',
    type: type,
    primitiveIds: [a.id, b.id],
    confidence: confidence.clamp(0, 1),
    evidence: ['Parâmetros geométricos URF comparados'],
    parameters: parameters,
  );
  Vector3? _direction(RecognitionCandidate c) {
    final raw = c.parameters['axis'] ?? c.parameters['normal'];
    return raw is List && raw.length == 3
        ? Vector3(
            (raw[0] as num).toDouble(),
            (raw[1] as num).toDouble(),
            (raw[2] as num).toDouble(),
          )
        : null;
  }

  Vector3? _origin(RecognitionCandidate c) {
    final raw = c.parameters['origin'] ?? c.parameters['center'];
    return raw is List && raw.length == 3
        ? Vector3(
            (raw[0] as num).toDouble(),
            (raw[1] as num).toDouble(),
            (raw[2] as num).toDouble(),
          )
        : null;
  }

  double? _radius(RecognitionCandidate c) =>
      (c.parameters['radius'] ?? c.parameters['majorRadius']) is num
      ? ((c.parameters['radius'] ?? c.parameters['majorRadius']) as num)
            .toDouble()
      : null;
}
