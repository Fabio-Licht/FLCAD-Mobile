import 'dart:io';
import 'dart:math' as math;

import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('G-124 Sketch Parametric Foundation', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('g124_');
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test(
      'line edits coordinates, length and angle without changing identity',
      () async {
        final api = const SketchEngineFactory().create(directory);
        api.createSketch('Sketch001');
        final line = api.builders.line.build(
          const SketchVector(0, 0),
          const SketchVector(10, 0),
        );
        final id = line.id;

        api.updateParameters(id, {'startX': 5, 'startY': 7});
        api.updateParameters(id, {'length': 100, 'angleDegrees': 45});

        final edited = api.entity(id)! as SketchLine;
        final start = SketchVector.fromJson(edited.parameters['start']);
        final end = SketchVector.fromJson(edited.parameters['end']);
        expect(edited.id, id);
        expect(start.x, 5);
        expect(start.y, 7);
        expect(edited.parameters['length'], closeTo(100, 1e-10));
        expect(edited.parameters['angleDegrees'], closeTo(45, 1e-10));
        expect(end.x, closeTo(5 + 100 / math.sqrt2, 1e-10));
        expect(end.y, closeTo(7 + 100 / math.sqrt2, 1e-10));
        expect(api.engine.undo(), isTrue);
        expect(
          api.entity(id)!.parameters['length'],
          closeTo(math.sqrt(74), 1e-10),
        );
        expect(api.engine.undo(), isTrue);
        expect(api.entity(id)!.parameters['length'], closeTo(10, 1e-10));
      },
    );

    test('circle radius and diameter are one coherent parameter', () {
      final api = const SketchEngineFactory().create(directory);
      api.createSketch('Sketch001');
      final circle = api.builders.circle.build(const SketchVector(1, 2), 5);
      api.updateParameters(circle.id, {'centerX': 10, 'diameter': 100});
      final edited = api.entity(circle.id)!;
      expect(SketchVector.fromJson(edited.parameters['center']).x, 10);
      expect(edited.parameters['radius'], 50);
    });

    test('arc edits center, radius and degree angles atomically', () {
      final api = const SketchEngineFactory().create(directory);
      api.createSketch('Sketch001');
      final arc = api.builders.arc.build(const SketchVector(0, 0), 5, 0, 1);
      api.updateParameters(arc.id, {
        'centerX': 3,
        'centerY': 4,
        'radius': 25,
        'startAngleDegrees': 30,
        'endAngleDegrees': 150,
      });
      final edited = api.entity(arc.id)!;
      expect(edited.parameters['radius'], 25);
      expect(edited.parameters['startAngle'], closeTo(math.pi / 6, 1e-12));
      expect(edited.parameters['endAngle'], closeTo(5 * math.pi / 6, 1e-12));
    });

    test('invalid radius cannot partially mutate an entity', () {
      final api = const SketchEngineFactory().create(directory);
      api.createSketch('Sketch001');
      final circle = api.builders.circle.build(const SketchVector(1, 2), 5);
      expect(
        () => api.updateParameters(circle.id, {'centerX': 99, 'radius': 0}),
        throwsArgumentError,
      );
      final restored = api.entity(circle.id)!;
      expect(SketchVector.fromJson(restored.parameters['center']).x, 1);
      expect(restored.parameters['radius'], 5);
    });

    test(
      'Hide/Show changes only visibility and preserves geometry instance',
      () async {
        final runtime = CadRuntime(kernels: KernelManager());
        addTearDown(runtime.dispose);
        await runtime.open('project', directory);
        const geometry = <String, dynamic>{
          'points': <List<double>>[
            <double>[0, 0, 0],
            <double>[1, 0, 0],
          ],
        };
        await runtime.upsertEntity(
          command: 'test.create',
          kind: CadDocumentEntityKind.curve,
          entity: const CadSceneEntity(
            id: 'curve:1',
            kind: CadSceneEntityKind.curve,
            geometry: geometry,
          ),
        );
        final before = runtime.scene.find('curve:1')!.geometry;

        await runtime.setEntityVisibility('curve:1', false);
        expect(runtime.scene.find('curve:1')!.visible, isFalse);
        expect(
          identical(runtime.scene.find('curve:1')!.geometry, before),
          isTrue,
        );
        await runtime.setEntityVisibility('curve:1', true);
        expect(runtime.scene.find('curve:1')!.visible, isTrue);
        expect(
          identical(runtime.scene.find('curve:1')!.geometry, before),
          isTrue,
        );
        expect(
          runtime.document!.entities['curve:1']!.data['sceneVisible'],
          isTrue,
        );
      },
    );
  });
}
