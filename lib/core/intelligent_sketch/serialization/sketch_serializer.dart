import '../constraints/sketch_constraint.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch.dart';
import '../models/sketch_context.dart';

class SketchSerializer {
  static Map<String, dynamic> toJson(IntelligentSketch s) => {
    'id': s.id,
    'projectId': s.projectId,
    'name': s.name,
    'mode': s.mode.name,
    'status': s.status.name,
    'contexts': s.contexts.map((e) => e.toJson()).toList(),
    'entities': s.entities.map((e) => e.toJson()).toList(),
    'constraints': s.constraints.map((e) => e.toJson()).toList(),
    'dna': s.dna.toJson(),
    'analytics': s.analytics.toJson(),
    'version': s.version,
    'createdAt': s.createdAt.toIso8601String(),
    'updatedAt': s.updatedAt.toIso8601String(),
    'intent': s.intent,
    'metadata': s.metadata,
  };
  static IntelligentSketch fromJson(Map<String, dynamic> j) =>
      IntelligentSketch(
        id: j['id'] as String,
        projectId: j['projectId'] as String,
        name: j['name'] as String,
        mode: SketchMode.values.byName(j['mode'] as String),
        status: SketchStatus.values.byName(j['status'] as String),
        contexts: (j['contexts'] as List)
            .map((e) => SketchGeometryContext.fromJson((e as Map).cast()))
            .toList(),
        entities: (j['entities'] as List)
            .map((e) => SketchEntity.fromJson((e as Map).cast()))
            .toList(),
        constraints: (j['constraints'] as List)
            .map((e) => SketchConstraint.fromJson((e as Map).cast()))
            .toList(),
        dna: SketchDNA.fromJson((j['dna'] as Map).cast()),
        analytics: SketchAnalytics.fromJson((j['analytics'] as Map).cast()),
        version: j['version'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        intent: j['intent'] as String?,
        metadata: (j['metadata'] as Map? ?? const {}).cast(),
      );
}
