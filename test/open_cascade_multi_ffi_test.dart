import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_bridge.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dll =
      Platform.environment['FLCAD_SOURCE_OCC_DLL'] ??
      r'C:\flcad_mobile\build\occ_mesh_stream\Release\flcad_opencascade.dll';
  final available = File(dll).existsSync();

  test(
    'FFI routes EXTRUDE MULTI separately from single Extrude',
    () async {
      final ffi = OpenCascadeFFI.load(path: dll);
      await ffi.initialize();
      final a = await ffi.createShape('CREATE PLANAR FACE', {
        'profilePoints': const [0, 0, 0, 10, 0, 0, 10, 10, 0, 0, 10, 0],
      }, CADShapeType.face);
      final b = await ffi.createShape('CREATE PLANAR FACE', {
        'profilePoints': const [20, 0, 0, 30, 0, 0, 30, 10, 0, 20, 10, 0],
      }, CADShapeType.face);
      OpenCascadeNativeShape? multi;
      try {
        multi = await ffi.createShape('EXTRUDE MULTI', {
          'inputs': [a.token, b.token],
          'direction': const [0, 0, 10],
          'output': 'solid',
          'draftAngleDegrees': 3,
          'symmetric': true,
          'tolerance': 1e-7,
        }, CADShapeType.compound);
        expect(multi.type, CADShapeType.compound);
        await expectLater(
          ffi.createShape('EXTRUDE MULTI', {
            'inputs': [a.token, a.token],
            'direction': const [0, 0, 10],
          }, CADShapeType.compound),
          throwsArgumentError,
        );
      } finally {
        if (multi != null) await ffi.destroyShape(multi.token);
        await ffi.destroyShape(a.token);
        await ffi.destroyShape(b.token);
        await ffi.shutdown();
      }
    },
    skip: available ? false : 'OCCT test DLL not available',
  );
}
