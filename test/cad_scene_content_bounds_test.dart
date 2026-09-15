import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_bounds.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new or reopened empty project uses deterministic origin frame', () {
    final scene = CadSceneGraph()
      ..upsert(
        const CadSceneEntity(
          id: 'project:world:xy-plane',
          kind: CadSceneEntityKind.plane,
          geometry: {
            'origin': [0.0, 0.0, 0.0],
            'visualSize': 60.0,
          },
        ),
      );
    final bounds = cadInitialProjectFitBounds(scene);
    expect(
      bounds.minimum.distanceTo(const Vector3(-10, -10, -10)),
      lessThan(1e-12),
    );
    expect(
      bounds.maximum.distanceTo(const Vector3(10, 10, 10)),
      lessThan(1e-12),
    );
    scene.dispose();
  });

  test(
    'initial project Fit uses CAD and Sketch/Solid bounds, never overlays',
    () {
      final scene = CadSceneGraph()
        ..upsert(_solid('STEP', const [0, 0, 0, 10, 20, 30]))
        ..upsert(
          const CadSceneEntity(
            id: 'Sketch001',
            kind: CadSceneEntityKind.sketch,
            geometry: {
              'points': [
                [-8.0, 7.0, 10.0],
                [0.0, 13.0, 20.0],
              ],
            },
          ),
        )
        ..upsert(_solid('Extrude001', const [-8, 7, 10, 0, 13, 20]))
        ..upsert(
          const CadSceneEntity(
            id: 'project:world:yz-plane',
            kind: CadSceneEntityKind.plane,
            geometry: {
              'origin': [999.0, 999.0, 999.0],
            },
          ),
        );
      final bounds = cadInitialProjectFitBounds(scene);
      expect(
        bounds.minimum.distanceTo(const Vector3(-8, 0, 0)),
        lessThan(1e-12),
      );
      expect(
        bounds.maximum.distanceTo(const Vector3(10, 20, 30)),
        lessThan(1e-12),
      );
      scene.dispose();
    },
  );

  test(
    'Fit bounds include CAD and Sketch but ignore construction overlays',
    () {
      final scene = CadSceneGraph()
        ..upsert(_solid('step', const [0, 0, 0, 10, 20, 30]))
        ..upsert(
          const CadSceneEntity(
            id: 'Sketch001',
            kind: CadSceneEntityKind.sketch,
            geometry: {
              'points': [
                [-8.0, 7.0, 10.0],
                [0.0, 13.0, 20.0],
              ],
            },
          ),
        )
        ..upsert(
          const CadSceneEntity(
            id: 'reference:huge',
            kind: CadSceneEntityKind.plane,
            geometry: {
              'origin': [10000.0, 10000.0, 10000.0],
              'visualSize': 100000.0,
            },
          ),
        );
      final bounds = cadSceneContentBounds(scene)!;
      expect(
        bounds.minimum.distanceTo(const Vector3(-8, 0, 0)),
        lessThan(1e-12),
      );
      expect(
        bounds.maximum.distanceTo(const Vector3(10, 20, 30)),
        lessThan(1e-12),
      );
      scene.dispose();
    },
  );

  test('reference presentation scale stays stable for in-bounds authoring', () {
    final scene = CadSceneGraph()
      ..upsert(_solid('step', const [0, 0, 0, 10, 20, 30]));
    final camera = CadCameraController()..viewScale = 45;
    final before = cadReferencePresentationScale(scene, camera);
    scene
      ..upsert(
        const CadSceneEntity(
          id: 'Sketch001',
          kind: CadSceneEntityKind.sketch,
          geometry: {
            'points': [
              [0.0, 7.0, 10.0],
              [0.0, 13.0, 20.0],
            ],
          },
        ),
      )
      ..upsert(_solid('Extrude001', const [-8, 7, 10, 0, 13, 20]));
    final after = cadReferencePresentationScale(scene, camera);
    expect((after - before).abs() / before, lessThan(.1));
    scene.dispose();
    camera.dispose();
  });
}

CadSceneEntity _solid(String id, List<double> bounds) => CadSceneEntity(
  id: id,
  kind: CadSceneEntityKind.solid,
  geometry: {
    'nodes': [bounds[0], bounds[1], bounds[2], bounds[3], bounds[4], bounds[5]],
    'triangles': const [0, 1, 1],
  },
);
