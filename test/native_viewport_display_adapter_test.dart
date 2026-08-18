import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native display adapter emits initial snapshot and incremental delta',
    () {
      final scene = CadSceneGraph();
      final geometry = <String, dynamic>{
        'nodes': <double>[0, 0, 0, 1, 0, 0, 0, 1, 0],
        'triangles': <int>[0, 1, 2],
      };
      scene.upsert(
        CadSceneEntity(
          id: 'mesh:1',
          kind: CadSceneEntityKind.mesh,
          geometry: geometry,
        ),
      );
      final adapter = CadSceneDisplayAdapter();
      final initial = adapter.initial(scene);
      expect(initial.entities, hasLength(1));
      expect(initial.entities.single['nodes'], same(geometry['nodes']));

      expect(adapter.delta(scene).entities, isEmpty);
      scene.select({'mesh:1'});
      final selectionDelta = adapter.delta(scene);
      expect(selectionDelta.entities, hasLength(1));
      expect(selectionDelta.entities.single['selected'], isTrue);
      expect(selectionDelta.entities.single.containsKey('nodes'), isFalse);

      scene.remove('mesh:1');
      expect(adapter.delta(scene).entities.single['removed'], isTrue);
    },
  );
}
