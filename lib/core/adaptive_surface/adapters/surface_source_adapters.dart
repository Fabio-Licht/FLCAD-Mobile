import '../../intelligent_sketch/models/sketch.dart';
import '../../reference_engine/models/reference_entity.dart';
import '../../smart_regions/models/geometry.dart';
import '../../smart_regions/models/smart_region.dart';
import '../builders/surface_builder.dart';

class SurfaceSourceAdapter {
  const SurfaceSourceAdapter();
  SurfaceBuildRequest fromRegion(
    SmartRegion region,
    MeshTopology mesh, {
    String intent = 'general',
  }) {
    final vertices = <int>{};
    for (final index in region.selection.indices) {
      final t = mesh.triangles[index];
      vertices.addAll([t.a, t.b, t.c]);
    }
    return SurfaceBuildRequest(
      projectId: region.projectId,
      sourceIds: [region.id],
      samples: vertices.map((i) => mesh.vertices[i]).toList(),
      intent: intent,
    );
  }

  SurfaceBuildRequest fromSketch(
    IntelligentSketch sketch, {
    String intent = 'general',
  }) => SurfaceBuildRequest(
    projectId: sketch.projectId,
    sourceIds: [sketch.id],
    samples: sketch.entities
        .expand((e) => e.anchors.map((a) => a.position))
        .toList(),
    intent: intent,
  );
  SurfaceBuildRequest fromReference(
    ReferenceEntity reference,
    List<Vec3> samples, {
    String intent = 'general',
  }) => SurfaceBuildRequest(
    projectId: reference.projectId,
    sourceIds: [reference.id],
    samples: samples,
    intent: intent,
  );
}
