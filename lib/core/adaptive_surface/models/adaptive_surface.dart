import 'surface_geometry.dart';

enum SurfaceMode { staticSurface, live }

enum SurfaceStage { alpha, beta, optimized, production }

enum SurfaceStatus { created, solving, valid, stale, invalid, repairing }

enum ManufacturingProcess {
  unknown,
  machining,
  casting,
  forming,
  additive,
  molding,
}

class SurfaceDNA {
  const SurfaceDNA(
    this.sourceSignature,
    this.geometrySignature,
    this.intentSignature,
    this.hash,
  );
  final String sourceSignature, geometrySignature, intentSignature, hash;
  Map<String, dynamic> toJson() => {
    'sourceSignature': sourceSignature,
    'geometrySignature': geometrySignature,
    'intentSignature': intentSignature,
    'hash': hash,
  };
  factory SurfaceDNA.fromJson(Map<String, dynamic> j) => SurfaceDNA(
    j['sourceSignature'] as String,
    j['geometrySignature'] as String,
    j['intentSignature'] as String,
    j['hash'] as String,
  );
}

class SurfaceMetrics {
  const SurfaceMetrics({
    required this.rmsError,
    required this.maxError,
    required this.meanError,
    required this.averageCurvature,
    required this.continuity,
    required this.confidence,
    required this.pointCount,
  });
  final double rmsError,
      maxError,
      meanError,
      averageCurvature,
      continuity,
      confidence;
  final int pointCount;
  Map<String, dynamic> toJson() => {
    'rmsError': rmsError,
    'maxError': maxError,
    'meanError': meanError,
    'averageCurvature': averageCurvature,
    'continuity': continuity,
    'confidence': confidence,
    'pointCount': pointCount,
  };
  factory SurfaceMetrics.fromJson(Map<String, dynamic> j) => SurfaceMetrics(
    rmsError: (j['rmsError'] as num).toDouble(),
    maxError: (j['maxError'] as num).toDouble(),
    meanError: (j['meanError'] as num).toDouble(),
    averageCurvature: (j['averageCurvature'] as num).toDouble(),
    continuity: (j['continuity'] as num).toDouble(),
    confidence: (j['confidence'] as num).toDouble(),
    pointCount: j['pointCount'] as int,
  );
}

class SurfaceScore {
  const SurfaceScore({
    required this.accuracy,
    required this.continuity,
    required this.curvature,
    required this.production,
    required this.aesthetics,
    required this.machinability,
    required this.total,
  });
  final double accuracy,
      continuity,
      curvature,
      production,
      aesthetics,
      machinability,
      total;
  Map<String, dynamic> toJson() => {
    'accuracy': accuracy,
    'continuity': continuity,
    'curvature': curvature,
    'production': production,
    'aesthetics': aesthetics,
    'machinability': machinability,
    'total': total,
  };
  factory SurfaceScore.fromJson(Map<String, dynamic> j) => SurfaceScore(
    accuracy: (j['accuracy'] as num).toDouble(),
    continuity: (j['continuity'] as num).toDouble(),
    curvature: (j['curvature'] as num).toDouble(),
    production: (j['production'] as num).toDouble(),
    aesthetics: (j['aesthetics'] as num).toDouble(),
    machinability: (j['machinability'] as num).toDouble(),
    total: (j['total'] as num).toDouble(),
  );
}

class AdaptiveSurface {
  const AdaptiveSurface({
    required this.id,
    required this.projectId,
    required this.name,
    required this.geometry,
    required this.mode,
    required this.stage,
    required this.status,
    required this.sourceIds,
    required this.neighborIds,
    required this.dna,
    required this.metrics,
    required this.score,
    required this.intent,
    required this.manufacturingProcess,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });
  final String id, projectId, name;
  final SurfaceGeometry geometry;
  final SurfaceMode mode;
  final SurfaceStage stage;
  final SurfaceStatus status;
  final List<String> sourceIds, neighborIds;
  final SurfaceDNA dna;
  final SurfaceMetrics metrics;
  final SurfaceScore score;
  final String intent;
  final ManufacturingProcess manufacturingProcess;
  final int version;
  final DateTime createdAt, updatedAt;
  final Map<String, dynamic> metadata;
  AdaptiveSurface copyWith({
    SurfaceGeometry? geometry,
    SurfaceStage? stage,
    SurfaceStatus? status,
    List<String>? neighborIds,
    SurfaceDNA? dna,
    SurfaceMetrics? metrics,
    SurfaceScore? score,
    String? intent,
    ManufacturingProcess? manufacturingProcess,
    int? version,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) => AdaptiveSurface(
    id: id,
    projectId: projectId,
    name: name,
    geometry: geometry ?? this.geometry,
    mode: mode,
    stage: stage ?? this.stage,
    status: status ?? this.status,
    sourceIds: sourceIds,
    neighborIds: neighborIds ?? this.neighborIds,
    dna: dna ?? this.dna,
    metrics: metrics ?? this.metrics,
    score: score ?? this.score,
    intent: intent ?? this.intent,
    manufacturingProcess: manufacturingProcess ?? this.manufacturingProcess,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    metadata: metadata ?? this.metadata,
  );
}
