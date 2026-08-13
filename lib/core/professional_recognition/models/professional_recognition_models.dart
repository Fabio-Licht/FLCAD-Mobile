import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_recognition/models/recognition_models.dart';

enum TopologicalRelationType {
  coaxial,
  concentric,
  parallel,
  perpendicular,
  coplanar,
  symmetric,
  tangent,
  continuous,
  aligned,
  linearPattern,
  circularPattern,
}

enum ManufacturingFeatureType {
  throughHole,
  blindHole,
  counterbore,
  countersink,
  pocket,
  boss,
  slot,
  rib,
  web,
  flange,
  pad,
  chamfer,
  fillet,
  groove,
  pattern,
  inferredThread,
  datumFeature,
  unknown,
}

class ResidualMap {
  const ResidualMap(
    this.pointResiduals,
    this.inlierIndices,
    this.outlierIndices,
  );
  final List<double> pointResiduals;
  final List<int> inlierIndices, outlierIndices;
}

class ProfessionalPrimitive {
  const ProfessionalPrimitive({
    required this.recognition,
    required this.residualMap,
    required this.pass,
    required this.auditTrail,
  });
  final PrimitiveRecognitionResult recognition;
  final ResidualMap residualMap;
  final int pass;
  final List<String> auditTrail;
}

class TopologicalRelation {
  const TopologicalRelation({
    required this.id,
    required this.type,
    required this.primitiveIds,
    required this.confidence,
    required this.evidence,
    required this.parameters,
  });
  final String id;
  final TopologicalRelationType type;
  final List<String> primitiveIds, evidence;
  final double confidence;
  final Map<String, dynamic> parameters;
}

class RecognizedPattern {
  const RecognizedPattern({
    required this.id,
    required this.kind,
    required this.memberIds,
    required this.confidence,
    required this.explanation,
    this.axis,
    this.planeNormal,
    this.spacing,
  });
  final String id, kind, explanation;
  final List<String> memberIds;
  final double confidence;
  final Vector3? axis, planeNormal;
  final double? spacing;
}

class ProfessionalFeature {
  const ProfessionalFeature({
    required this.id,
    required this.type,
    required this.regionIds,
    required this.primitiveIds,
    required this.confidence,
    required this.explanation,
    required this.dna,
    required this.evidence,
  });
  final String id, explanation, dna;
  final ManufacturingFeatureType type;
  final List<String> regionIds, primitiveIds, evidence;
  final double confidence;
}

class ProbabilisticInference {
  const ProbabilisticInference(
    this.kind,
    this.probability,
    this.explanation,
    this.evidence,
  );
  final String kind, explanation;
  final double probability;
  final List<String> evidence;
}

class ActiveRecognitionAdvice {
  const ActiveRecognitionAdvice(this.action, this.reason, this.priority);
  final String action, reason;
  final double priority;
}

class ProfessionalRecognitionReport {
  const ProfessionalRecognitionReport({
    required this.projectId,
    required this.primitives,
    required this.relations,
    required this.features,
    required this.patterns,
    required this.functions,
    required this.manufacturing,
    required this.advice,
    required this.elapsed,
    required this.pendingRegionIds,
    required this.createdAt,
  });
  final String projectId;
  final List<ProfessionalPrimitive> primitives;
  final List<TopologicalRelation> relations;
  final List<ProfessionalFeature> features;
  final List<RecognizedPattern> patterns;
  final List<ProbabilisticInference> functions, manufacturing;
  final List<ActiveRecognitionAdvice> advice;
  final Duration elapsed;
  final List<String> pendingRegionIds;
  final DateTime createdAt;
  double get averageConfidence {
    final values = [
      ...primitives.map((e) => e.recognition.dna.confidence),
      ...features.map((e) => e.confidence),
    ];
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  }

  double get recognizedCoverage {
    final values = primitives
        .map((e) => e.recognition.winner.statistics.coverage)
        .toList();
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, int> get statisticsByType {
    final result = <String, int>{};
    for (final primitive in primitives) {
      result.update(
        primitive.recognition.winner.type.name,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }
}
