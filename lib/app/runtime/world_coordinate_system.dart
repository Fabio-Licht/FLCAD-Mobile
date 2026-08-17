import '../../core/cad_document/cad_document.dart';

/// Creates the immutable document entities that represent the project world
/// coordinate system. They are document state; the scene graph only projects
/// them.
class WorldCoordinateSystem {
  const WorldCoordinateSystem._();

  static String prefix(String projectId) => '$projectId:world:';

  static bool isProtected(CadDocumentEntity entity) =>
      entity.data['systemProtected'] == true;

  static CadDocument ensure(CadDocument document) {
    final required = entities(document.projectId);
    if (required.keys.every(document.entities.containsKey)) return document;
    return document.mutate(
      command: 'system.world-coordinate-system.initialize',
      upsert: [
        for (final entry in required.entries)
          if (!document.entities.containsKey(entry.key)) entry.value,
      ],
    );
  }

  static Map<String, CadDocumentEntity> entities(String projectId) {
    CadDocumentEntity entity(
      String suffix,
      String name,
      String sceneKind,
      Map<String, dynamic> geometry, {
      bool transparent = false,
    }) {
      final id = '${prefix(projectId)}$suffix';
      return CadDocumentEntity(
        id: id,
        kind: CadDocumentEntityKind.reference,
        data: {
          'name': name,
          'group': 'World Coordinate System',
          'systemProtected': true,
          'sceneKind': sceneKind,
          'sceneGeometry': geometry,
          'sceneVisible': true,
          'sceneTransparent': transparent,
        },
      );
    }

    const origin = [0.0, 0.0, 0.0];
    const x = [1.0, 0.0, 0.0];
    const y = [0.0, 1.0, 0.0];
    const z = [0.0, 0.0, 1.0];
    return {
      '${prefix(projectId)}coordinate-system': entity(
        'coordinate-system',
        'World Coordinate System',
        'coordinateSystem',
        {
          'type': 'coordinateSystem',
          'origin': origin,
          'xAxis': x,
          'yAxis': y,
          'zAxis': z,
          'visualLength': 30.0,
        },
      ),
      '${prefix(projectId)}origin': entity(
        'origin',
        'Origin (0, 0, 0)',
        'point',
        {'type': 'point', 'position': origin},
      ),
      '${prefix(projectId)}x-axis': entity('x-axis', 'X Axis', 'axis', {
        'type': 'axis',
        'origin': origin,
        'direction': x,
        'visualLength': 30.0,
        'axisColor': 'x',
      }),
      '${prefix(projectId)}y-axis': entity('y-axis', 'Y Axis', 'axis', {
        'type': 'axis',
        'origin': origin,
        'direction': y,
        'visualLength': 30.0,
        'axisColor': 'y',
      }),
      '${prefix(projectId)}z-axis': entity('z-axis', 'Z Axis', 'axis', {
        'type': 'axis',
        'origin': origin,
        'direction': z,
        'visualLength': 30.0,
        'axisColor': 'z',
      }),
      '${prefix(projectId)}xy-plane': entity('xy-plane', 'XY Plane', 'plane', {
        'type': 'plane',
        'origin': origin,
        'normal': z,
        'xDirection': x,
        'visualSize': 60.0,
        'planeColor': 'xy',
      }, transparent: true),
      '${prefix(projectId)}xz-plane': entity('xz-plane', 'XZ Plane', 'plane', {
        'type': 'plane',
        'origin': origin,
        'normal': y,
        'xDirection': x,
        'visualSize': 60.0,
        'planeColor': 'xz',
      }, transparent: true),
      '${prefix(projectId)}yz-plane': entity('yz-plane', 'YZ Plane', 'plane', {
        'type': 'plane',
        'origin': origin,
        'normal': x,
        'xDirection': y,
        'visualSize': 60.0,
        'planeColor': 'yz',
      }, transparent: true),
    };
  }
}
