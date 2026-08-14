import '../../surface_topology/models/surface_topology_models.dart';

enum ContinuityLevel { g0, g1, g2, g3, notApplicable }

enum SurfaceQualityHealth { excellent, good, acceptable, warning, critical }

class CurvatureAnalysis {
  const CurvatureAnalysis({
    required this.minimum,
    required this.maximum,
    required this.averageMinimum,
    required this.averageMaximum,
    required this.mean,
    required this.gaussian,
    required this.gradient,
    required this.stability,
    required this.equivalentRadius,
  });
  final double minimum,
      maximum,
      averageMinimum,
      averageMaximum,
      mean,
      gaussian,
      gradient,
      stability,
      equivalentRadius;
  Map<String, dynamic> toJson() => {
    'minimum': minimum,
    'maximum': maximum,
    'averageMinimum': averageMinimum,
    'averageMaximum': averageMaximum,
    'mean': mean,
    'gaussian': gaussian,
    'gradient': gradient,
    'stability': stability,
    'equivalentRadius': equivalentRadius.isFinite ? equivalentRadius : null,
  };
}

class ReflectionAnalysis {
  const ReflectionAnalysis({
    required this.lines,
    required this.environment,
    required this.flow,
    required this.quality,
  });
  final List<double> lines;
  final double environment, flow, quality;
  Map<String, dynamic> toJson() => {
    'reflectionLines': lines,
    'environmentReflection': environment,
    'surfaceFlow': flow,
    'quality': quality,
  };
}

class ZebraAnalysis {
  const ZebraAnalysis({
    required this.horizontal,
    required this.vertical,
    required this.radial,
    required this.free,
    required this.density,
    required this.contrast,
  });
  final double horizontal, vertical, radial, free, density, contrast;
  Map<String, dynamic> toJson() => {
    'horizontal': horizontal,
    'vertical': vertical,
    'radial': radial,
    'free': free,
    'density': density,
    'contrast': contrast,
    'source': 'native surface normals',
  };
}

class DraftAnalysis {
  const DraftAnalysis({
    required this.direction,
    required this.minimumAngle,
    required this.maximumAngle,
    required this.negative,
    required this.critical,
    required this.approved,
  });
  final List<double> direction;
  final double minimumAngle, maximumAngle;
  final int negative, critical, approved;
  Map<String, dynamic> toJson() => {
    'direction': direction,
    'minimumAngle': minimumAngle,
    'maximumAngle': maximumAngle,
    'negativeRegions': negative,
    'criticalRegions': critical,
    'approvedRegions': approved,
  };
}

class ContinuityAssessment {
  const ContinuityAssessment({
    required this.id,
    required this.firstPatchId,
    required this.secondPatchId,
    required this.discontinuity,
    required this.angle,
    required this.maximumError,
    required this.meanError,
    required this.rms,
    required this.effective,
    required this.level,
    required this.classification,
  });
  final String id, firstPatchId, secondPatchId, classification;
  final double discontinuity, angle, maximumError, meanError, rms, effective;
  final ContinuityLevel level;
  Map<String, dynamic> toJson() => {
    'id': id,
    'firstPatch': firstPatchId,
    'secondPatch': secondPatchId,
    'discontinuity': discontinuity,
    'angle': angle,
    'maximumError': maximumError,
    'meanError': meanError,
    'rms': rms,
    'effective': effective,
    'level': level.name,
    'classification': classification,
  };
}

class PatchQuality {
  const PatchQuality({
    required this.patch,
    required this.curvature,
    required this.reflection,
    required this.zebra,
    required this.draft,
    required this.continuityScore,
    required this.curvatureScore,
    required this.reflectionScore,
    required this.draftScore,
    required this.topologyScore,
    required this.recognitionConfidence,
    required this.surfaceConfidence,
    required this.overall,
    required this.health,
  });
  final PatchEntity patch;
  final CurvatureAnalysis curvature;
  final ReflectionAnalysis reflection;
  final ZebraAnalysis zebra;
  final DraftAnalysis draft;
  final double continuityScore,
      curvatureScore,
      reflectionScore,
      draftScore,
      topologyScore,
      recognitionConfidence,
      surfaceConfidence,
      overall;
  final SurfaceQualityHealth health;
  Map<String, dynamic> toJson() => {
    'patchId': patch.id,
    'continuity': continuityScore,
    'curvature': curvature.toJson(),
    'reflection': reflection.toJson(),
    'zebra': zebra.toJson(),
    'draft': draft.toJson(),
    'scores': {
      'continuity': continuityScore,
      'curvature': curvatureScore,
      'reflection': reflectionScore,
      'draft': draftScore,
      'topology': topologyScore,
      'recognitionConfidence': recognitionConfidence,
      'surfaceConfidence': surfaceConfidence,
      'overall': overall,
    },
    'health': health.name,
    'geometryModified': false,
  };
}

class ContinuityGraph {
  const ContinuityGraph(this.nodes, this.edges);
  final Map<String, Map<String, dynamic>> nodes;
  final Map<String, Set<String>> edges;
  Map<String, dynamic> toJson() => {
    'nodes': nodes,
    'edges': edges.map((k, v) => MapEntry(k, v.toList()..sort())),
  };
}

class SurfaceQualityAnalytics {
  const SurfaceQualityAnalytics({
    required this.elapsed,
    required this.patchCount,
    required this.continuityDistribution,
    required this.averageCurvature,
    required this.reflectionScore,
    required this.draftScore,
    required this.qualityScore,
  });
  final Duration elapsed;
  final int patchCount;
  final Map<ContinuityLevel, int> continuityDistribution;
  final double averageCurvature, reflectionScore, draftScore, qualityScore;
  Map<String, dynamic> toJson() => {
    'patches': patchCount,
    'continuityDistribution': continuityDistribution.map(
      (k, v) => MapEntry(k.name, v),
    ),
    'averageCurvature': averageCurvature,
    'reflectionScore': reflectionScore,
    'draftScore': draftScore,
    'qualityScore': qualityScore,
    'elapsedMicros': elapsed.inMicroseconds,
  };
}

class QualityAdvice {
  const QualityAdvice(this.targetId, this.suggestion, this.reason);
  final String targetId, suggestion, reason;
  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'suggestion': suggestion,
    'reason': reason,
    'consultative': true,
  };
}

class SurfaceQualityReport {
  const SurfaceQualityReport({
    required this.id,
    required this.topologyReportId,
    required this.patchQualities,
    required this.continuity,
    required this.graph,
    required this.analytics,
    required this.advice,
    required this.createdAt,
  });
  final String id, topologyReportId;
  final List<PatchQuality> patchQualities;
  final List<ContinuityAssessment> continuity;
  final ContinuityGraph graph;
  final SurfaceQualityAnalytics analytics;
  final List<QualityAdvice> advice;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'topologyReportId': topologyReportId,
    'patchQualities': patchQualities.map((e) => e.toJson()).toList(),
    'continuity': continuity.map((e) => e.toJson()).toList(),
    'graph': graph.toJson(),
    'analytics': analytics.toJson(),
    'advisor': advice.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'geometryModified': false,
  };
}
