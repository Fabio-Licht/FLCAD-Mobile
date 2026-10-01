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
    'FFI routes signed solid and surface Revolve to the native ABI',
    () async {
      final ffi = OpenCascadeFFI.load(path: dll);
      await ffi.initialize();
      final face = await ffi.createShape('CREATE PLANAR FACE', {
        'profilePoints': const [0, 2, 0, 4, 2, 0, 4, 5, 0, 0, 5, 0],
      }, CADShapeType.face);
      final start = await ffi.createShape('CREATE VERTEX', {
        'x': 0,
        'y': 2,
        'z': 0,
      }, CADShapeType.vertex);
      final end = await ffi.createShape('CREATE VERTEX', {
        'x': 4,
        'y': 2,
        'z': 0,
      }, CADShapeType.vertex);
      final edge = await ffi.createShape('CREATE EDGE', {
        'start': start.token,
        'end': end.token,
      }, CADShapeType.edge);
      final wire = await ffi.createShape('CREATE WIRE', {
        'edges': [edge.token],
      }, CADShapeType.wire);
      final created = <OpenCascadeNativeShape>[];
      try {
        created.add(
          await ffi.createShape('REVOLVE', {
            'inputs': [face.token],
            'axisOrigin': const [0, 0, 0],
            'axisDirection': const [1, 0, 0],
            'angleDegrees': 120,
            'output': 'solid',
          }, CADShapeType.solid),
        );
        created.add(
          await ffi.createShape('REVOLVE', {
            'inputs': [face.token],
            'axisOrigin': const [0, 0, 0],
            'axisDirection': const [1, 0, 0],
            'angleDegrees': -120,
            'output': 'solid',
          }, CADShapeType.solid),
        );
        created.add(
          await ffi.createShape('REVOLVE', {
            'inputs': [wire.token],
            'axisOrigin': const [0, 0, 0],
            'axisDirection': const [1, 0, 0],
            'angleDegrees': 90,
            'output': 'surface',
          }, CADShapeType.face),
        );

        await expectLater(
          ffi.createShape('REVOLVE', {
            'inputs': [face.token],
            'axisOrigin': const [0, 0, 0],
            'axisDirection': const [0, 0, 0],
            'angleDegrees': 90,
            'output': 'solid',
          }, CADShapeType.solid),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('REVOLVE_AXIS_INVALID'),
            ),
          ),
        );
        await expectLater(
          ffi.createShape('REVOLVE', {
            'inputs': [wire.token],
            'axisOrigin': const [0, 0, 0],
            'axisDirection': const [1, 0, 0],
            'angleDegrees': 90,
            'output': 'solid',
          }, CADShapeType.solid),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('REVOLVE_PROFILE_OPEN'),
            ),
          ),
        );
      } finally {
        for (final shape in created.reversed) {
          await ffi.destroyShape(shape.token);
        }
        await ffi.destroyShape(wire.token);
        await ffi.destroyShape(edge.token);
        await ffi.destroyShape(start.token);
        await ffi.destroyShape(end.token);
        await ffi.destroyShape(face.token);
        await ffi.shutdown();
      }
    },
    skip: available ? false : 'OCCT test DLL not available',
  );
}
