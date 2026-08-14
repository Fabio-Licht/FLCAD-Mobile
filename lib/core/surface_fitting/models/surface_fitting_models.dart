import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../geometric_recognition/models/recognition_models.dart';

enum SurfaceFitHealth { excellent, good, medium, low, rejected }

enum SurfaceFitStatus { accepted, rejected, notApplicable }

class ResidualStatistics {
  const ResidualStatistics({
    required this.values,
    required this.rms,
    required this.maximum,
    required this.mean,
    required this.standardDeviation,
    required this.distribution,
  });
  final List<double> values;
  final double rms, maximum, mean, standardDeviation;
  final Map<String, int> distribution;
  Map<String, dynamic> toJson() => {
    'rms': rms.isFinite ? rms : null,
    'maximum': maximum.isFinite ? maximum : null,
    'mean': mean.isFinite ? mean : null,
    'standardDeviation': standardDeviation.isFinite ? standardDeviation : null,
    'distribution': distribution,
    'count': values.length,
  };
}

class SurfaceFitCandidate {
  const SurfaceFitCandidate({
    required this.regionId,
    required this.type,
    required this.parameters,
    required this.residuals,
    required this.confidence,
    required this.valid,
    required this.algorithm,
  });
  final String regionId, algorithm;
  final PrimitiveType type;
  final Map<String, dynamic> parameters;
  final ResidualStatistics residuals;
  final double confidence;
  final bool valid;
}

class SurfaceEntity {
  const SurfaceEntity({
    required this.id,
    required this.recognitionRegionId,
    required this.primitiveType,
    required this.handle,
    required this.bounds,
    required this.area,
    required this.parameters,
    required this.residuals,
    required this.confidence,
    required this.health,
    required this.timestamp,
    required this.status,
  });
  final String id, recognitionRegionId;
  final PrimitiveType primitiveType;
  final ShapeHandle? handle;
  final KernelBounds bounds;
  final double area, confidence;
  final Map<String, dynamic> parameters;
  final ResidualStatistics residuals;
  final SurfaceFitHealth health;
  final DateTime timestamp;
  final SurfaceFitStatus status;
  Map<String, dynamic> toJson() => {
    'id': id,
    'recognitionRegion': recognitionRegionId,
    'primitiveType': primitiveType.name,
    'surfaceHandle': handle?.toJson(),
    'boundingBox': bounds.toJson(),
    'area': area,
    'parameters': parameters,
    'residuals': residuals.toJson(),
    'confidence': confidence,
    'health': health.name,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'native': handle != null,
  };
}

class SurfaceFittingAnalytics {
  const SurfaceFittingAnalytics({
    required this.elapsed,
    required this.distribution,
    required this.averageRms,
    required this.averageResidual,
    required this.averageConfidence,
    required this.accepted,
    required this.rejected,
  });
  final Duration elapsed;
  final Map<PrimitiveType, int> distribution;
  final double averageRms, averageResidual, averageConfidence;
  final int accepted, rejected;
  Map<String, dynamic> toJson() => {
    'surfaceCount': accepted + rejected,
    'distribution': distribution.map((k, v) => MapEntry(k.name, v)),
    'averageRms': averageRms,
    'averageResidual': averageResidual,
    'averageConfidence': averageConfidence,
    'elapsedMicros': elapsed.inMicroseconds,
    'accepted': accepted,
    'rejected': rejected,
  };
}

class SurfaceFitAdvice {
  const SurfaceFitAdvice(this.surfaceId, this.suggestion, this.reason);
  final String surfaceId, suggestion, reason;
  Map<String, dynamic> toJson() => {
    'surfaceId': surfaceId,
    'suggestion': suggestion,
    'reason': reason,
    'consultative': true,
  };
}

class SurfaceFittingReport {
  const SurfaceFittingReport({
    required this.id,
    required this.recognitionReportId,
    required this.surfaces,
    required this.analytics,
    required this.advice,
    required this.createdAt,
  });
  final String id, recognitionReportId;
  final List<SurfaceEntity> surfaces;
  final SurfaceFittingAnalytics analytics;
  final List<SurfaceFitAdvice> advice;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'recognitionReportId': recognitionReportId,
    'surfaces': surfaces.map((e) => e.toJson()).toList(),
    'analytics': analytics.toJson(),
    'advisor': advice.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}
