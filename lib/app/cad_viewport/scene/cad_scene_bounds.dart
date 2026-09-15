import 'dart:math' as math;

import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../camera/cad_camera_controller.dart';
import 'cad_scene_graph.dart';

typedef CadSceneBounds = ({Vector3 minimum, Vector3 maximum});

bool _isDurableCad(CadSceneEntity entity) => switch (entity.kind) {
  CadSceneEntityKind.mesh ||
  CadSceneEntityKind.surface ||
  CadSceneEntityKind.solid => true,
  _ => false,
};

/// Bounds used by Fit: real CAD plus, optionally, the authored Sketch profile.
/// Viewport chrome, construction references and transient previews never alter
/// the framing of the part.
CadSceneBounds? cadSceneContentBounds(
  CadSceneGraph scene, {
  bool includeSketch = true,
}) {
  var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  var maxZ = double.negativeInfinity;

  void include(Object? raw) {
    if (raw is! List || raw.length < 3 || raw.take(3).any((v) => v is! num)) {
      return;
    }
    final x = (raw[0] as num).toDouble();
    final y = (raw[1] as num).toDouble();
    final z = (raw[2] as num).toDouble();
    if (!x.isFinite || !y.isFinite || !z.isFinite) return;
    minX = math.min(minX, x);
    minY = math.min(minY, y);
    minZ = math.min(minZ, z);
    maxX = math.max(maxX, x);
    maxY = math.max(maxY, y);
    maxZ = math.max(maxZ, z);
  }

  for (final entity in scene.entities.where((item) => item.visible)) {
    if (_isDurableCad(entity)) {
      final nodes = entity.geometry['nodes'];
      if (nodes is List) {
        for (var index = 0; index + 2 < nodes.length; index += 3) {
          include([nodes[index], nodes[index + 1], nodes[index + 2]]);
        }
      }
    } else if (includeSketch && entity.kind == CadSceneEntityKind.sketch) {
      final points = entity.geometry['points'];
      if (points is List) {
        for (final point in points) {
          include(point);
        }
      }
      final segments = entity.geometry['segments'];
      if (segments is List) {
        for (final segment in segments.whereType<List>()) {
          for (final point in segment) {
            include(point);
          }
        }
      }
    }
  }
  if (!minX.isFinite || !maxX.isFinite) return null;
  return (
    minimum: Vector3(minX, minY, minZ),
    maximum: Vector3(maxX, maxY, maxZ),
  );
}

/// Presentation-only reference size. The model term follows true CAD bounds;
/// the view term prevents WCS/reference planes becoming unreadable on screen.
double cadReferencePresentationScale(
  CadSceneGraph scene,
  CadCameraController camera,
) {
  final bounds = cadSceneContentBounds(scene, includeSketch: false);
  final diagonal = bounds == null
      ? 0.0
      : (bounds.maximum - bounds.minimum).length;
  final viewSpan = camera.projectionMode == CadProjectionMode.orthographic
      ? camera.viewScale
      : (camera.eye - camera.target).length * .75;
  return math.max(math.max(diagonal * .12, viewSpan * .12), 1.0);
}
