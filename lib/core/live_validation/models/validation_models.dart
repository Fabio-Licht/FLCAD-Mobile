import '../../cad_kernel/models/kernel_models.dart';
import '../../utils/id_generator.dart';

enum ValidationSourceType {
  meshCad,
  meshFeature,
  meshSketch,
  meshReference,
  meshSurface,
  bodyBody,
  regionRegion,
}

enum LiveValidationStatus {
  idle,
  running,
  paused,
  stopped,
  ready,
  kernelUnavailable,
  unsupportedOperation,
  invalid,
  failed,
}

enum ValidationUpdateType {
  incremental,
  region,
  feature,
  reference,
  rebuild,
  alignment,
  surface,
  sketch,
  extrude,
  revolve,
  sweep,
  loft,
  datum,
}

class ValidationSource {
  const ValidationSource({required this.id, required this.type, this.shape});
  final String id;
  final ValidationSourceType type;
  final ShapeHandle? shape;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'shape': shape?.toJson(),
  };
}

class ValidationParameters {
  ValidationParameters({
    this.tolerance = .1,
    this.warningThreshold = .075,
    this.criticalThreshold = .15,
    this.colorScale = 'blue-green-yellow-red',
  });
  double tolerance, warningThreshold, criticalThreshold;
  String colorScale;
  Map<String, dynamic> toJson() => {
    'tolerance': tolerance,
    'warningThreshold': warningThreshold,
    'criticalThreshold': criticalThreshold,
    'colorScale': colorScale,
  };
}

class DeviationSample {
  const DeviationSample({
    required this.regionId,
    required this.deviation,
    required this.confidence,
  });
  final String regionId;
  final double deviation, confidence;
  Map<String, dynamic> toJson() => {
    'regionId': regionId,
    'deviation': deviation,
    'confidence': confidence,
  };
}

class ValidationMetrics {
  const ValidationMetrics({
    required this.maximumDeviation,
    required this.averageDeviation,
    required this.rms,
    required this.standardDeviation,
    required this.withinTolerancePercent,
    required this.outsideTolerancePercent,
    required this.criticalAreaPercent,
    required this.confidence,
    required this.stability,
    required this.overallQuality,
  });
  final double maximumDeviation,
      averageDeviation,
      rms,
      standardDeviation,
      withinTolerancePercent,
      outsideTolerancePercent,
      criticalAreaPercent,
      confidence,
      stability,
      overallQuality;
  Map<String, dynamic> toJson() => {
    'maximumDeviation': maximumDeviation,
    'averageDeviation': averageDeviation,
    'rms': rms,
    'standardDeviation': standardDeviation,
    'withinTolerancePercent': withinTolerancePercent,
    'outsideTolerancePercent': outsideTolerancePercent,
    'criticalAreaPercent': criticalAreaPercent,
    'confidence': confidence,
    'stability': stability,
    'overallQuality': overallQuality,
  };
}

class LiveValidationSession {
  LiveValidationSession({
    required this.source,
    required this.target,
    required this.parameters,
    String? id,
  }) : id = id ?? 'validation:${IdGenerator.generate()}',
       createdAt = DateTime.now().toUtc(),
       updatedAt = DateTime.now().toUtc();
  final String id;
  final ValidationSource source, target;
  final ValidationParameters parameters;
  final DateTime createdAt;
  DateTime updatedAt;
  LiveValidationStatus status = LiveValidationStatus.idle;
  ValidationMetrics? metrics;
  final Map<String, DeviationSample> samples = {};
  final List<String> affectedRegions = [], dependencies = [], diagnostics = [];
  String? responsibleFeature;
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.toJson(),
    'target': target.toJson(),
    'parameters': parameters.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status.name,
    'metrics': metrics?.toJson(),
    'samples': samples.values.map((e) => e.toJson()).toList(),
    'affectedRegions': affectedRegions,
    'dependencies': dependencies,
    'diagnostics': diagnostics,
    'responsibleFeature': responsibleFeature,
  };
}

class ValidationExecutionResult {
  const ValidationExecutionResult(
    this.status, {
    this.metrics,
    this.samples = const [],
    this.diagnostics = const [],
  });
  final LiveValidationStatus status;
  final ValidationMetrics? metrics;
  final List<DeviationSample> samples;
  final List<String> diagnostics;
  bool get success => status == LiveValidationStatus.ready && metrics != null;
}
