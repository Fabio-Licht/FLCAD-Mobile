import '../../../core/surface_generation/models/surface_generation_models.dart';
import '../../../core/surface_generation/models/surface_topology.dart';
import '../scene/cad_scene_graph.dart';

class SurfaceSceneAdapter {
  const SurfaceSceneAdapter();

  CadSceneEntity adapt(GeneratedSurface surface, {bool preview = false}) {
    final mode = SurfaceDisplayMode.values.byName(
      surface.parameters['displayMode'] as String? ??
          SurfaceDisplayMode.shadedWithEdges.name,
    );
    return CadSceneEntity(
      id: preview ? 'preview:${surface.surfaceId}' : surface.surfaceId,
      kind: preview ? CadSceneEntityKind.preview : CadSceneEntityKind.surface,
      geometry: {
        'surfaceKind': surface.kind.name,
        'parameters': surface.parameters,
        'continuity': surface.continuity.name,
        'confidence': surface.confidence,
        'valid': surface.valid,
        'handle': surface.handle.toJson(),
        if (surface.parameters['displayNodes'] is List)
          'nodes': surface.parameters['displayNodes'],
        if (surface.parameters['displayTriangles'] is List)
          'triangles': surface.parameters['displayTriangles'],
        if (!preview) 'displayColor': 'definitiveSurface',
        if (!preview) 'shaded': mode != SurfaceDisplayMode.wireframe,
        if (!preview) 'displayMode': mode.name,
      },
      transparent: preview || mode == SurfaceDisplayMode.transparent,
    );
  }

  CadSceneEntity planarPreview({
    required String id,
    required List<double> origin,
    required List<double> normal,
    required double width,
    required double height,
    required double quality,
    required String continuity,
  }) => CadSceneEntity(
    id: id,
    kind: CadSceneEntityKind.preview,
    geometry: {
      'surfaceKind': 'plane',
      'parameters': {
        'origin': origin,
        'normal': normal,
        'width': width,
        'height': height,
      },
      'quality': quality,
      'continuity': continuity,
    },
    transparent: true,
  );
}
