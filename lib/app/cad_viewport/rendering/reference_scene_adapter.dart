import '../../../core/reference_engine/models/reference_entity.dart';
import '../../../core/reference_engine/models/reference_geometry.dart';
import '../scene/cad_scene_graph.dart';

class ReferenceSceneAdapter {
  const ReferenceSceneAdapter();
  CadSceneEntity adapt(ReferenceEntity reference) => CadSceneEntity(
    id: reference.id,
    kind: switch (reference.geometry) {
      PlaneGeometry() => CadSceneEntityKind.plane,
      AxisGeometry() => CadSceneEntityKind.axis,
      PointGeometry() => CadSceneEntityKind.point,
      CoordinateSystemGeometry() => CadSceneEntityKind.coordinateSystem,
      CurveGeometry() => CadSceneEntityKind.curve,
    },
    geometry: reference.geometry.toJson(),
    transparent: reference.geometry is PlaneGeometry,
  );
}
