import '../models/adaptive_surface.dart';
import '../models/surface_geometry.dart';

class SurfaceSerializer {
  static Map<String, dynamic> toJson(AdaptiveSurface s) => {
    'id': s.id,
    'projectId': s.projectId,
    'name': s.name,
    'geometry': s.geometry.toJson(),
    'mode': s.mode.name,
    'stage': s.stage.name,
    'status': s.status.name,
    'sourceIds': s.sourceIds,
    'neighborIds': s.neighborIds,
    'dna': s.dna.toJson(),
    'metrics': s.metrics.toJson(),
    'score': s.score.toJson(),
    'intent': s.intent,
    'manufacturingProcess': s.manufacturingProcess.name,
    'version': s.version,
    'createdAt': s.createdAt.toIso8601String(),
    'updatedAt': s.updatedAt.toIso8601String(),
    'metadata': s.metadata,
  };
  static AdaptiveSurface fromJson(Map<String, dynamic> j) => AdaptiveSurface(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    name: j['name'] as String,
    geometry: ParametricSurfaceGeometry.fromJson((j['geometry'] as Map).cast()),
    mode: SurfaceMode.values.byName(j['mode'] as String),
    stage: SurfaceStage.values.byName(j['stage'] as String),
    status: SurfaceStatus.values.byName(j['status'] as String),
    sourceIds: (j['sourceIds'] as List).cast(),
    neighborIds: (j['neighborIds'] as List? ?? const []).cast(),
    dna: SurfaceDNA.fromJson((j['dna'] as Map).cast()),
    metrics: SurfaceMetrics.fromJson((j['metrics'] as Map).cast()),
    score: SurfaceScore.fromJson((j['score'] as Map).cast()),
    intent: j['intent'] as String,
    manufacturingProcess: ManufacturingProcess.values.byName(
      j['manufacturingProcess'] as String,
    ),
    version: j['version'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    metadata: (j['metadata'] as Map? ?? const {}).cast(),
  );
}
