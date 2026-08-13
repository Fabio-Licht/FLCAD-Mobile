import '../constraints/sketch_constraint.dart';
import '../entities/sketch_entity.dart';
import 'sketch_context.dart';

enum SketchMode { staticSketch, live }

enum SketchStatus {
  created,
  underConstrained,
  solved,
  overConstrained,
  stale,
  invalid,
}

class SketchDNA {
  const SketchDNA(this.contextSignature, this.geometrySignature, this.hash);
  final String contextSignature;
  final String geometrySignature;
  final String hash;
  Map<String, dynamic> toJson() => {
    'contextSignature': contextSignature,
    'geometrySignature': geometrySignature,
    'hash': hash,
  };
  factory SketchDNA.fromJson(Map<String, dynamic> json) => SketchDNA(
    json['contextSignature'] as String,
    json['geometrySignature'] as String,
    json['hash'] as String,
  );
}

class SketchAnalytics {
  const SketchAnalytics({
    required this.length,
    required this.area,
    required this.averageCurvature,
    required this.continuity,
    required this.tangency,
    required this.closed,
    required this.quality,
    required this.degree,
    required this.segmentCount,
  });
  final double length, area, averageCurvature, continuity, tangency, quality;
  final bool closed;
  final int degree, segmentCount;
  Map<String, dynamic> toJson() => {
    'length': length,
    'area': area,
    'averageCurvature': averageCurvature,
    'continuity': continuity,
    'tangency': tangency,
    'closed': closed,
    'quality': quality,
    'degree': degree,
    'segmentCount': segmentCount,
  };
  factory SketchAnalytics.fromJson(Map<String, dynamic> json) =>
      SketchAnalytics(
        length: (json['length'] as num).toDouble(),
        area: (json['area'] as num).toDouble(),
        averageCurvature: (json['averageCurvature'] as num).toDouble(),
        continuity: (json['continuity'] as num).toDouble(),
        tangency: (json['tangency'] as num).toDouble(),
        closed: json['closed'] as bool,
        quality: (json['quality'] as num).toDouble(),
        degree: json['degree'] as int,
        segmentCount: json['segmentCount'] as int,
      );
}

class IntelligentSketch {
  const IntelligentSketch({
    required this.id,
    required this.projectId,
    required this.name,
    required this.mode,
    required this.status,
    required this.contexts,
    required this.entities,
    required this.constraints,
    required this.dna,
    required this.analytics,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.intent,
    this.metadata = const {},
  });
  final String id, projectId, name;
  final SketchMode mode;
  final SketchStatus status;
  final List<SketchGeometryContext> contexts;
  final List<SketchEntity> entities;
  final List<SketchConstraint> constraints;
  final SketchDNA dna;
  final SketchAnalytics analytics;
  final int version;
  final DateTime createdAt, updatedAt;
  final String? intent;
  final Map<String, dynamic> metadata;

  IntelligentSketch copyWith({
    SketchStatus? status,
    List<SketchGeometryContext>? contexts,
    List<SketchEntity>? entities,
    List<SketchConstraint>? constraints,
    SketchDNA? dna,
    SketchAnalytics? analytics,
    int? version,
    DateTime? updatedAt,
    String? intent,
    Map<String, dynamic>? metadata,
  }) => IntelligentSketch(
    id: id,
    projectId: projectId,
    name: name,
    mode: mode,
    status: status ?? this.status,
    contexts: contexts ?? this.contexts,
    entities: entities ?? this.entities,
    constraints: constraints ?? this.constraints,
    dna: dna ?? this.dna,
    analytics: analytics ?? this.analytics,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    intent: intent ?? this.intent,
    metadata: metadata ?? this.metadata,
  );
}
