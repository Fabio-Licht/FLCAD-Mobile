import 'dart:math' as math;

import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/rendering/cad_canvas_normal_pipeline.dart';
import 'package:flcad_mobile/app/navigation/cad_camera_navigation_adapter.dart';
import 'package:flcad_mobile/app/navigation/navigation_contracts.dart';
import 'package:flcad_mobile/app/navigation/navigation_engine.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'slow subpixel orbit retains displacement independently of event count',
    () {
      CadCameraController camera() => CadCameraController()..resize(1000, 700);
      final one = camera(), many = camera();
      NavigationEngine engine(CadCameraController c) => NavigationEngine(
        camera: CadCameraNavigationAdapter(c),
        resolvePoint: (_, _) => null,
        profile: NavigationProfile.cadOpenCascade,
      );
      final a = engine(one), b = engine(many);
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      a.pointerDown(x: 0, y: 0, buttons: 5);
      b.pointerDown(x: 0, y: 0, buttons: 5);
      a.pointerMove(x: 30, y: 0, buttons: 5);
      for (var i = 1; i <= 600; i++) {
        b.pointerMove(x: i * .05, y: 0, buttons: 5);
      }
      expect(one.eye.distanceTo(many.eye), lessThan(1e-9));
      expect(one.up.distanceTo(many.up), lessThan(1e-9));
      a.pointerUp(x: 30, y: 0, buttons: 0);
      b.pointerUp(x: 30, y: 0, buttons: 0);
    },
  );
  test(
    'Fit encloses all corners in portrait and landscape for both lenses',
    () {
      for (final aspect in [.3, 1.0, 3.0]) {
        for (final projection in CadProjectionMode.values) {
          final camera = CadCameraController()..resize(600 * aspect, 600);
          camera.projectionMode = projection;
          const min = Vector3(-120, -70, -30), max = Vector3(120, 70, 30);
          camera.fit(min, max);
          final before = camera.snapshot();
          for (final x in [min.x, max.x]) {
            for (final y in [min.y, max.y]) {
              for (final z in [min.z, max.z]) {
                final p = camera.viewProjectionMatrix.transformPoint(
                  Vector3(x, y, z),
                );
                expect(p.x.abs(), lessThan(1));
                expect(p.y.abs(), lessThan(1));
                expect(p.z, inInclusiveRange(-1, 1));
              }
            }
          }
          camera.fit(min, max);
          expect(camera.eye.distanceTo(before.eye), lessThan(1e-10));
          expect(camera.target.distanceTo(before.target), lessThan(1e-10));
          expect(camera.up, before.up);
        }
      }
    },
  );

  test(
    'middle pan preserves orientation; explicit modifier orbit and zoom are separate',
    () {
      final camera = CadCameraController()..resize(1000, 700);
      camera.fit(const Vector3(-100, -80, -30), const Vector3(100, 80, 30));
      final engine = NavigationEngine(
        camera: CadCameraNavigationAdapter(camera),
        resolvePoint: (_, _) => null,
        profile: NavigationProfile.cadOpenCascade,
      );
      addTearDown(engine.dispose);
      final before = camera.snapshot();
      engine.pointerDown(x: 500, y: 350, buttons: 4);
      for (var i = 1; i <= 100; i++) {
        engine.pointerMove(x: 500 + i.toDouble(), y: 350 + i / 2, buttons: 4);
        expect(
          (camera.target - camera.eye).distanceTo(before.target - before.eye),
          lessThan(1e-9),
        );
        expect(camera.up, before.up);
      }
      engine.pointerUp(x: 600, y: 400, buttons: 0);
      final pivot = camera.focusPoint;
      final distance = camera.eye.distanceTo(pivot);
      engine.pointerDown(x: 600, y: 400, buttons: 4, shift: true);
      engine.pointerMove(x: 620, y: 400, buttons: 4, shift: true);
      expect(engine.state, NavigationState.orbiting);
      expect(camera.focusPoint, pivot);
      expect(camera.eye.distanceTo(pivot), closeTo(distance, 1e-9));
      expect(camera.eye.distanceTo(before.eye), greaterThan(0));
      engine.pointerUp(x: 620, y: 400, buttons: 0);
      engine.pointerDown(
        x: 620,
        y: 400,
        buttons: 4,
        control: true,
        shift: true,
      );
      engine.pointerMove(
        x: 620,
        y: 410,
        buttons: 4,
        control: true,
        shift: true,
      );
      expect(engine.state, NavigationState.zooming);
      engine.pointerUp(x: 620, y: 410, buttons: 0);
    },
  );

  test(
    'wheel is continuous, reciprocal, bounded and independent of event subdivision',
    () {
      for (final projection in CadProjectionMode.values) {
        CadCameraController camera() => CadCameraController()
          ..resize(1000, 700)
          ..projectionMode = projection
          ..fit(const Vector3(-100, -100, -100), const Vector3(100, 100, 100));
        final one = camera(), many = camera();
        NavigationEngine engine(CadCameraController c) => NavigationEngine(
          camera: CadCameraNavigationAdapter(c),
          resolvePoint: (_, _) => null,
          profile: NavigationProfile.cadOpenCascade,
        );
        final a = engine(one), b = engine(many);
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        final initial = one.eye.distanceTo(one.target), scale = one.viewScale;
        a.wheel(x: 0, y: 0, deltaY: -120);
        for (var i = 0; i < 12; i++) {
          b.wheel(x: 0, y: 0, deltaY: -10);
        }
        expect(one.viewScale / scale, closeTo(math.exp(-.048), 1e-10));
        expect(one.eye.distanceTo(many.eye), lessThan(1e-9));
        a.wheel(x: 0, y: 0, deltaY: 120);
        expect(one.eye.distanceTo(one.target), closeTo(initial, 1e-9));
        expect(one.viewScale, closeTo(scale, 1e-9));
        for (var i = 0; i < 500; i++) {
          a.wheel(x: 0, y: 0, deltaY: -240);
        }
        final close = one.snapshot();
        a.wheel(x: 0, y: 0, deltaY: -240);
        expect(one.eye.distanceTo(close.eye), lessThan(1e-9));
        expect(one.viewScale, close.viewScale);
        for (var i = 0; i < 500; i++) {
          a.wheel(x: 0, y: 0, deltaY: 240);
        }
        final far = one.snapshot();
        a.wheel(x: 0, y: 0, deltaY: 240);
        expect(one.eye.distanceTo(far.eye), lessThan(1e-9));
        expect(one.viewScale, closeTo(far.viewScale, 1e-9));
        final invalid = one.snapshot();
        a.wheel(x: 0, y: 0, deltaY: double.nan);
        expect(one.eye, invalid.eye);
      }
    },
  );

  test('surface normals survive chunking and never blend across CAD faces', () {
    final chunks = CadCanvasNormalPipeline.build(
      [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
      [0, 1, 2, 3, 4, 5],
      nativeNormals: [0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0],
      trianglesPerChunk: 1,
    );
    expect(chunks.length, 2);
    expect(chunks.first.normals.toList(), [0, 0, 1, 0, 0, 1, 0, 0, 1]);
    expect(chunks.last.normals.toList(), [1, 0, 0, 1, 0, 0, 1, 0, 0]);
    expect(chunks.last.indices.toList(), [0, 1, 2]);
  });

  test(
    'standard views initialize model-relative zoom limits without a first-wheel jump',
    () {
      for (final view in CadStandardView.values) {
        final camera = CadCameraController()..resize(300, 1000);
        camera.setStandardView(
          view,
          const Vector3(-300, -200, -50),
          const Vector3(300, 200, 50),
        );
        final distance = camera.eye.distanceTo(camera.target);
        camera.zoom(math.exp(-.048));
        expect(
          camera.eye.distanceTo(camera.target) / distance,
          closeTo(math.exp(-.048), 1e-10),
        );
        final pivot = camera.focusPoint;
        final before = camera.viewProjectionMatrix.transformPoint(pivot);
        camera.orbit(.15, -.08);
        final after = camera.viewProjectionMatrix.transformPoint(pivot);
        expect(before.x, closeTo(after.x, 1e-10));
        expect(before.y, closeTo(after.y, 1e-10));
      }
    },
  );
}
