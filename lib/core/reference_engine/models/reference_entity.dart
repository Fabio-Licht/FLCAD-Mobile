import 'reference_geometry.dart';

enum ReferenceMode { staticReference, live }

enum ReferenceStatus { valid, stale, rebuilding, invalid, deleted }

class ReferenceDNA {
  const ReferenceDNA(
    this.kind,
    this.sourceFingerprint,
    this.geometrySignature,
    this.hash,
  );
  final String kind, sourceFingerprint, geometrySignature, hash;
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'sourceFingerprint': sourceFingerprint,
    'geometrySignature': geometrySignature,
    'hash': hash,
  };
  factory ReferenceDNA.fromJson(Map<String, dynamic> j) => ReferenceDNA(
    j['kind'] as String,
    j['sourceFingerprint'] as String,
    j['geometrySignature'] as String,
    j['hash'] as String,
  );
}

class ReferenceAnalytics {
  const ReferenceAnalytics({
    required this.precision,
    required this.rmsError,
    required this.maxDeviation,
    required this.confidence,
    required this.fitQuality,
    required this.areaUsed,
    required this.coverage,
    required this.pointCount,
  });
  final double precision,
      rmsError,
      maxDeviation,
      confidence,
      fitQuality,
      areaUsed,
      coverage;
  final int pointCount;
  Map<String, dynamic> toJson() => {
    'precision': precision,
    'rmsError': rmsError,
    'maxDeviation': maxDeviation,
    'confidence': confidence,
    'fitQuality': fitQuality,
    'areaUsed': areaUsed,
    'coverage': coverage,
    'pointCount': pointCount,
  };
  factory ReferenceAnalytics.fromJson(Map<String, dynamic> j) =>
      ReferenceAnalytics(
        precision: (j['precision'] as num).toDouble(),
        rmsError: (j['rmsError'] as num).toDouble(),
        maxDeviation: (j['maxDeviation'] as num).toDouble(),
        confidence: (j['confidence'] as num).toDouble(),
        fitQuality: (j['fitQuality'] as num).toDouble(),
        areaUsed: (j['areaUsed'] as num).toDouble(),
        coverage: (j['coverage'] as num).toDouble(),
        pointCount: j['pointCount'] as int,
      );
}

class ReferenceRecipe {
  const ReferenceRecipe(this.builderId, this.parameters, this.sourceIds);
  final String builderId;
  final Map<String, dynamic> parameters;
  final List<String> sourceIds;
  Map<String, dynamic> toJson() => {
    'builderId': builderId,
    'parameters': parameters,
    'sourceIds': sourceIds,
  };
  factory ReferenceRecipe.fromJson(Map<String, dynamic> j) => ReferenceRecipe(
    j['builderId'] as String,
    (j['parameters'] as Map).cast(),
    (j['sourceIds'] as List).cast<String>(),
  );
}

class ReferenceEntity {
  const ReferenceEntity({
    required this.id,
    required this.projectId,
    required this.name,
    required this.geometry,
    required this.mode,
    required this.status,
    required this.dna,
    required this.analytics,
    required this.recipe,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.dependencies,
    required this.metadata,
  });
  final String id, projectId, name;
  final ReferenceGeometry geometry;
  final ReferenceMode mode;
  final ReferenceStatus status;
  final ReferenceDNA dna;
  final ReferenceAnalytics analytics;
  final ReferenceRecipe recipe;
  final int version;
  final DateTime createdAt, updatedAt;
  final List<String> dependencies;
  final Map<String, dynamic> metadata;
  ReferenceEntity copyWith({
    ReferenceGeometry? geometry,
    ReferenceStatus? status,
    ReferenceDNA? dna,
    ReferenceAnalytics? analytics,
    int? version,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) => ReferenceEntity(
    id: id,
    projectId: projectId,
    name: name,
    geometry: geometry ?? this.geometry,
    mode: mode,
    status: status ?? this.status,
    dna: dna ?? this.dna,
    analytics: analytics ?? this.analytics,
    recipe: recipe,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    dependencies: dependencies,
    metadata: metadata ?? this.metadata,
  );
}
