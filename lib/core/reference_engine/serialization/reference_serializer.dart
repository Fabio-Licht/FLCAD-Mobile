import '../models/reference_entity.dart';
import '../models/reference_geometry.dart';

abstract final class ReferenceSerializer {
  static Map<String, dynamic> toJson(ReferenceEntity r) => {
    'id': r.id,
    'projectId': r.projectId,
    'name': r.name,
    'geometry': r.geometry.toJson(),
    'mode': r.mode.name,
    'status': r.status.name,
    'dna': r.dna.toJson(),
    'analytics': r.analytics.toJson(),
    'recipe': r.recipe.toJson(),
    'version': r.version,
    'createdAt': r.createdAt.toIso8601String(),
    'updatedAt': r.updatedAt.toIso8601String(),
    'dependencies': r.dependencies,
    'metadata': r.metadata,
  };
  static ReferenceEntity fromJson(Map<String, dynamic> j) => ReferenceEntity(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    name: j['name'] as String,
    geometry: geometryFromJson((j['geometry'] as Map).cast()),
    mode: ReferenceMode.values.firstWhere((v) => v.name == j['mode']),
    status: ReferenceStatus.values.firstWhere((v) => v.name == j['status']),
    dna: ReferenceDNA.fromJson((j['dna'] as Map).cast()),
    analytics: ReferenceAnalytics.fromJson((j['analytics'] as Map).cast()),
    recipe: ReferenceRecipe.fromJson((j['recipe'] as Map).cast()),
    version: j['version'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    dependencies: (j['dependencies'] as List).cast<String>(),
    metadata: (j['metadata'] as Map).cast(),
  );
}
