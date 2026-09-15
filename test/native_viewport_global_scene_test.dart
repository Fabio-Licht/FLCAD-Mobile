import 'dart:async';
import 'dart:io';

import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/native/integrated_native_viewport_widget.dart';
import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/app/cad_viewport/professional_cad_viewport_widget.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const channel = MethodChannel('flcad/native_viewport');
const positions = [-1.0, -1.0, 0.0, 1.0, -1.0, 0.0, 0.0, 1.0, 0.0];

CadSceneEntity step() => CadSceneEntity(
  id: 'step',
  kind: CadSceneEntityKind.mesh,
  geometry: {
    'nodes': positions,
    'triangles': [0, 1, 2],
    'rootLinearRgb': [0.2, 0.4, 0.6],
    'brepPresentation': {
      'nodes': positions,
      'triangles': [0, 1, 2],
      'topologicalEdges': [
        [-1.0, -1.0, 0.0, 1.0, -1.0, 0.0],
      ],
    },
  },
);

CadSceneEntity lod() => CadSceneEntity(
  id: 'lod',
  kind: CadSceneEntityKind.mesh,
  geometry: {
    'nodes': positions,
    'triangles': [0, 1, 2],
    'normals': [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0],
    'stlPresentation': true,
    'presentationLod': {
      'version': 1,
      'measurementSafe': false,
      'method': 'spatial-clustering-v1',
      'originalTriangles': 1956958,
      'originalVertices': 1956958 * 3,
      'displayTriangles': 1,
      'displayVertices': 3,
    },
  },
);

List<CadSceneEntity> viewportOverlays() => const [
  CadSceneEntity(
    id: 'project:world:coordinate-system',
    kind: CadSceneEntityKind.coordinateSystem,
    geometry: {
      'type': 'coordinateSystem',
      'origin': [0.0, 0.0, 0.0],
      'xAxis': [1.0, 0.0, 0.0],
      'yAxis': [0.0, 1.0, 0.0],
      'zAxis': [0.0, 0.0, 1.0],
    },
  ),
  CadSceneEntity(
    id: 'project:world:origin',
    kind: CadSceneEntityKind.point,
    geometry: {
      'type': 'point',
      'position': [0.0, 0.0, 0.0],
    },
  ),
  CadSceneEntity(
    id: 'project:world:xy-plane',
    kind: CadSceneEntityKind.plane,
    geometry: {
      'type': 'plane',
      'origin': [0.0, 0.0, 0.0],
      'normal': [0.0, 0.0, 1.0],
    },
  ),
  CadSceneEntity(
    id: 'transform-gizmo-x',
    kind: CadSceneEntityKind.axis,
    geometry: {
      'origin': [0.0, 0.0, 0.0],
      'direction': [1.0, 0.0, 0.0],
      'visualLength': 25.0,
    },
  ),
];

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final sources in [
    [step()],
    [lod()],
    [step(), lod()],
  ]) {
    testWidgets(
      'one native viewport owns ${sources.map((e) => e.id).join('+')} and light Hide/Show',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 900));
        final scene = CadSceneGraph()..replaceAll(sources);
        final camera = CadCameraController(
          eye: const Vector3(0, 0, 5),
          target: Vector3.zero,
        );
        final bridge = NativeViewportBridge();
        final messages = <MethodCall>[];
        final host = <String, Map>{};
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            messages.add(call);
            if (call.method == 'initialize') return 42;
            if (call.method == 'shutdown') host.clear();
            if (call.method == 'snapshot' || call.method == 'delta') {
              final message = call.arguments as Map;
              if (call.method == 'snapshot') host.clear();
              for (final e in (message['entities'] as List).cast<Map>()) {
                final id = e['id'] as String;
                if (e['removed'] == true) {
                  host.remove(id);
                } else {
                  host[id] = {...?host[id], ...e};
                }
              }
              return message['revision'];
            }
            if (call.method == 'pick') {
              return {
                'entityId': sources.first.id,
                'kind': 1,
                'subId': 1,
                'point': [0.0, 0.0, 0.0],
              };
            }
            return null;
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: IntegratedCadViewportWidget(
              scene: scene,
              camera: camera,
              nativeBridgeFactory: () => bridge,
              onPick: (pick) => scene.select({pick.entityId}),
            ),
          ),
        );
        await frames(tester);
        ProfessionalCadViewportWidget viewport() =>
            tester.widget(find.byType(ProfessionalCadViewportWidget));
        expect(find.byType(Texture), findsOneWidget);
        expect(viewport().renderMeshes, isFalse);
        expect(viewport().enableEntityHover, isFalse);
        expect(host.keys, unorderedEquals(sources.map((e) => e.id)));
        expect(messages.where((c) => c.method == 'snapshot'), hasLength(1));
        final snapshot =
            messages.firstWhere((c) => c.method == 'snapshot').arguments as Map;
        expect(bridge.acknowledgedSceneRevision, snapshot['revision']);
        final cache =
            (tester.state(find.byType(ProfessionalCadViewportWidget))
                        as dynamic)
                    .meshRenderCaches
                as Map;
        expect(cache, isEmpty);

        for (final source in sources) {
          for (final visible in [false, true]) {
            scene.upsert(source.copyWith(visible: visible));
            await frames(tester);
            expect(host[source.id]!['visible'], visible);
            final delta =
                messages.lastWhere((c) => c.method == 'delta').arguments as Map;
            expect(
              (delta['entities'] as List).every(
                (e) => !(e as Map).containsKey('nodes'),
              ),
              isTrue,
            );
            expect(find.byType(Texture), findsOneWidget);
            expect(viewport().renderMeshes, isFalse);
          }
        }
        viewport().onNormalTap!(const Offset(700, 500));
        await frames(tester);
        expect(host[sources.first.id]!['selected'], isTrue);
        expect(camera.focusPoint.distanceTo(Vector3.zero), lessThan(1e-12));
        expect(messages.where((c) => c.method == 'snapshot'), hasLength(1));

        // The same approved frontend/controller handles pointers for either owner.
        final rect = tester.getRect(find.byType(ProfessionalCadViewportWidget));
        final start = rect.center + const Offset(0, 80);
        final before = camera.snapshot();
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kMiddleMouseButton,
        );
        await gesture.down(start);
        await gesture.moveBy(const Offset(30, 20));
        await gesture.up();
        await frames(tester);
        expect(
          (camera.target - camera.eye).distanceTo(before.target - before.eye),
          lessThan(1e-9),
        );
        expect(camera.eye.distanceTo(before.eye), greaterThan(0));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        final orbit = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kMiddleMouseButton,
        );
        await orbit.down(start);
        await orbit.moveBy(const Offset(35, -15));
        await orbit.up();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await frames(tester);
        expect(
          (camera.target - camera.eye).distanceTo(before.target - before.eye),
          greaterThan(0),
        );
        final distance = (camera.eye - camera.target).length;
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: start,
            scrollDelta: const Offset(0, -20),
          ),
        );
        await frames(tester);
        expect((camera.eye - camera.target).length, lessThan(distance));
        expect(
          messages.where((c) => ['orbit', 'pan', 'zoom'].contains(c.method)),
          isEmpty,
        );
        final pose =
            messages.lastWhere((c) => c.method == 'setCamera').arguments as Map;
        expect(pose['eye'], [
          camera.presentationEye.x,
          camera.presentationEye.y,
          camera.presentationEye.z,
        ]);
        await tester.tap(find.text('Flutter Canvas'));
        await frames(tester);
        expect(find.byType(Texture), findsNothing);
        expect(viewport().renderMeshes, isTrue);
        expect(host, isEmpty);
        expect(bridge.adapter.retainedGeometryCount, 0);
        final inactiveCallCount = messages.length;
        scene.select({});
        camera.panViewportPixels(10, -5);
        await frames(tester);
        expect(messages, hasLength(inactiveCallCount));
        final handoffPose = camera.snapshot();
        await tester.tap(find.text('Native GPU'));
        await frames(tester);
        expect(find.byType(Texture), findsOneWidget);
        expect(viewport().renderMeshes, isFalse);
        expect(host.keys, unorderedEquals(sources.map((e) => e.id)));
        expect(host.values.every((e) => e['selected'] == false), isTrue);
        expect(camera.eye.distanceTo(handoffPose.eye), lessThan(1e-12));
        expect(camera.target.distanceTo(handoffPose.target), lessThan(1e-12));
        expect(messages.where((c) => c.method == 'snapshot'), hasLength(2));
        await tester.pumpWidget(const SizedBox());
        await frames(tester);
        expect(host, isEmpty);
        expect(bridge.adapter.retainedGeometryCount, 0);
        scene.dispose();
        camera.dispose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      },
      skip: !Platform.isWindows,
    );
  }

  testWidgets(
    'STEP with WCS placement gizmo and ViewCube stays on Native GPU',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      final overlays = viewportOverlays();
      final scene = CadSceneGraph()..replaceAll([step(), ...overlays]);
      final camera = CadCameraController(
        eye: const Vector3(0, 0, 5),
        target: Vector3.zero,
      );
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'initialize') return 42;
        if (call.method == 'snapshot' || call.method == 'delta') {
          return (call.arguments as Map)['revision'];
        }
        return null;
      });
      expect(nativeSceneUnsupportedReason(scene, style: 0), isNull);
      expect(overlays, everyElement(predicate(isNativeViewportOverlay)));

      await tester.pumpWidget(
        MaterialApp(
          home: IntegratedCadViewportWidget(scene: scene, camera: camera),
        ),
      );
      await frames(tester);

      expect(find.byType(Texture), findsOneWidget);
      expect(
        find.byKey(const ValueKey('professional-view-cube')),
        findsOneWidget,
      );
      final viewport = tester.widget<ProfessionalCadViewportWidget>(
        find.byType(ProfessionalCadViewportWidget),
      );
      expect(viewport.renderMeshes, isFalse);
      expect(scene.entities.where(isNativeViewportOverlay), hasLength(4));
      final snapshot =
          calls.singleWhere((call) => call.method == 'snapshot').arguments
              as Map;
      expect(
        (snapshot['entities'] as List).map((entity) => (entity as Map)['id']),
        ['step'],
      );

      final cameraCallsBeforeFit = calls
          .where((call) => call.method == 'setCamera')
          .length;
      await tester.tap(find.byTooltip('Fit View'));
      await frames(tester);
      expect(
        calls.where((call) => call.method == 'setCamera').length,
        greaterThan(cameraCallsBeforeFit),
      );
      expect(find.byType(Texture), findsOneWidget);

      scene.select({'step'});
      await frames(tester);
      expect(find.byType(Texture), findsOneWidget);
      scene.upsert(step().copyWith(visible: false));
      await frames(tester);
      expect(find.byType(Texture), findsOneWidget);
      scene.upsert(step());
      await frames(tester);
      expect(find.byType(Texture), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await frames(tester);
      scene.dispose();
      camera.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'invalid STL LOD payload uses categorized global Canvas fallback',
    (tester) async {
      final valid = lod();
      final invalid = CadSceneEntity(
        id: valid.id,
        kind: valid.kind,
        geometry: {
          ...valid.geometry,
          // `triangles` is the protocol field consumed as the native index
          // buffer. A fractional index is not a valid Native payload; Canvas
          // can still recover deterministically through its integer projection.
          'triangles': [0, 1, 1.5],
        },
      );
      final scene = CadSceneGraph()..replaceAll([step(), invalid]);
      final camera = CadCameraController();
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return call.method == 'initialize' ? 42 : null;
      });

      expect(
        nativeSceneUnsupportedReason(scene, style: 0),
        contains('malha CAD: indices triangulares'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: IntegratedCadViewportWidget(scene: scene, camera: camera),
        ),
      );
      await frames(tester);
      expect(find.byType(Texture), findsNothing);
      expect(find.textContaining('malha CAD'), findsOneWidget);
      expect(calls, isEmpty);

      scene.upsert(invalid.copyWith(visible: false));
      await frames(tester);
      expect(nativeSceneUnsupportedReason(scene, style: 0), isNull);
      expect(find.byType(Texture), findsOneWidget);
      final snapshot =
          calls.singleWhere((call) => call.method == 'snapshot').arguments
              as Map;
      expect(
        (snapshot['entities'] as List).map((entity) => (entity as Map)['id']),
        ['step'],
      );

      await tester.pumpWidget(const SizedBox());
      await frames(tester);
      scene.dispose();
      camera.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'unsupported visible entity falls back globally before any scene publish',
    (tester) async {
      final unknown = const CadSceneEntity(
        id: 'curve',
        kind: CadSceneEntityKind.curve,
        geometry: {
          'points': [
            [0.0, 0.0, 0.0],
            [1.0, 1.0, 1.0],
          ],
        },
      );
      final scene = CadSceneGraph()..replaceAll([step(), lod(), unknown]);
      final camera = CadCameraController();
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return call.method == 'initialize' ? 42 : null;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: IntegratedCadViewportWidget(scene: scene, camera: camera),
        ),
      );
      await frames(tester);
      expect(find.byType(Texture), findsNothing);
      expect(
        tester
            .widget<ProfessionalCadViewportWidget>(
              find.byType(ProfessionalCadViewportWidget),
            )
            .renderMeshes,
        isTrue,
      );
      expect(find.textContaining('toda a cena'), findsOneWidget);
      expect(find.textContaining('curva CAD'), findsOneWidget);
      expect(find.textContaining('geometria não suportada'), findsNothing);
      expect(
        calls.where(
          (c) => ['snapshot', 'delta', 'setCamera', 'pick'].contains(c.method),
        ),
        isEmpty,
      );
      scene.upsert(unknown.copyWith(visible: false));
      await frames(tester);
      expect(find.byType(Texture), findsOneWidget);
      final snapshot =
          calls.singleWhere((c) => c.method == 'snapshot').arguments as Map;
      expect(
        (snapshot['entities'] as List).map((e) => (e as Map)['id']),
        unorderedEquals(['step', 'lod']),
      );
      scene.upsert(unknown);
      await frames(tester);
      expect(find.byType(Texture), findsNothing);
      expect(
        tester
            .widget<ProfessionalCadViewportWidget>(
              find.byType(ProfessionalCadViewportWidget),
            )
            .renderMeshes,
        isTrue,
      );
      expect(calls.where((c) => c.method == 'snapshot'), hasLength(1));
      await tester.pumpWidget(const SizedBox());
      await frames(tester);
      scene.dispose();
      camera.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
    skip: !Platform.isWindows,
  );

  test(
    'visibility gate coalesces latest state and acknowledges without geometry',
    () async {
      final scene = CadSceneGraph()..replaceAll([step(), lod()]);
      final bridge = NativeViewportBridge();
      final calls = <MethodCall>[];
      final gate = Completer<int>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') return 42;
            if (call.method == 'delta' && !gate.isCompleted) return gate.future;
            if (call.method == 'snapshot' || call.method == 'delta') {
              return (call.arguments as Map)['revision'];
            }
            return null;
          });
      expect(await bridge.initialize(800, 600), isTrue);
      await bridge.sendInitial(scene);
      final source = scene.find('step')!;
      // Recreated wrapper/color list is not a new geometry definition.
      scene.upsert(
        CadSceneEntity(
          id: source.id,
          kind: source.kind,
          visible: false,
          geometry: {
            ...source.geometry,
            'rootLinearRgb': [0.2, 0.4, 0.6],
          },
        ),
      );
      final draining = bridge.sendDelta(scene);
      await Future<void>.value();
      scene.upsert(source);
      bridge.sendDelta(scene);
      scene.upsert(source.copyWith(visible: false));
      bridge.sendDelta(scene);
      scene.upsert(source);
      bridge.sendDelta(scene);
      expect(calls.where((c) => c.method == 'delta'), hasLength(1));
      final first = calls.last.arguments as Map;
      expect((first['entities'] as List).single, {
        'id': 'step',
        'kind': 'mesh',
        'visible': false,
        'selected': false,
      });
      gate.complete(first['revision'] as int);
      await draining;
      expect(calls.where((c) => c.method == 'delta'), hasLength(2));
      final latest = calls.last.arguments as Map;
      expect((latest['entities'] as List).single['visible'], isTrue);
      expect((latest['entities'] as List).single.containsKey('nodes'), isFalse);
      expect(bridge.acknowledgedSceneRevision, latest['revision']);
      await bridge.deactivate();
      bridge.dispose();
      scene.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
    skip: !Platform.isWindows,
  );
}
