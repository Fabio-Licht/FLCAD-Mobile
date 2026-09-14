import 'dart:convert';

import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_document/entity_placement.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/geometric_kernel/linear_algebra/matrices.dart';
import 'package:flcad_mobile/app/runtime/managed_placement_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('world composition rotates around the moved local pivot', () {
    final placement = EntityPlacement.identity([
      1,
      2,
      0,
    ]).translate(10, 0, 0).rotate(0, 0, 1, 90);
    final pivot = placement.matrix.transformPoint(const Vector3(1, 2, 0));
    expect(pivot.x, closeTo(11, 1e-10));
    expect(pivot.y, closeTo(2, 1e-10));
    final point = placement.matrix.transformPoint(const Vector3(2, 2, 0));
    expect(point.x, closeTo(11, 1e-10));
    expect(point.y, closeTo(3, 1e-10));
    final reverse = EntityPlacement.identity([
      1,
      2,
      0,
    ]).rotate(0, 0, 1, 90).translate(10, 0, 0);
    for (var i = 0; i < 16; i++) {
      expect(
        reverse.matrix.values[i],
        closeTo(placement.matrix.values[i], 1e-10),
      );
    }
  });
  test('world rotation order is noncommutative and degrees convert once', () {
    final a = EntityPlacement.identity([
      0,
      0,
      0,
    ]).rotate(1, 0, 0, 90).rotate(0, 1, 0, 90);
    final b = EntityPlacement.identity([
      0,
      0,
      0,
    ]).rotate(0, 1, 0, 90).rotate(1, 0, 0, 90);
    final pa = a.matrix.transformPoint(const Vector3(0, 1, 0));
    final pb = b.matrix.transformPoint(const Vector3(0, 1, 0));
    expect(pa.x, closeTo(1, 1e-10));
    expect(pb.z, closeTo(1, 1e-10));
  });
  test(
    'strict serializable stack roundtrip has no residence or matrix identity',
    () {
      final a = EntityPlacement.identity([
        2,
        3,
        4,
      ]).translate(-2, 8, 1).rotate(0, 0, 1, 135);
      final json = jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>;
      final b = EntityPlacement.fromJson(json);
      expect(b.matrix.values, a.matrix.values);
      expect(
        json.keys,
        unorderedEquals([
          'schema',
          'version',
          'frameUnit',
          'space',
          'pivotLocal',
          'operations',
        ]),
      );
      expect(() => b.pivotLocal[0] = 0, throwsUnsupportedError);
      expect(() => b.operations.clear(), throwsUnsupportedError);
    },
  );
  test(
    'invalid schema, scale, quaternion, unit and singular matrix rejected',
    () {
      final json = EntityPlacement.identity([0, 0, 0]).toJson();
      for (final update in <Map<String, dynamic>>[
        {'schema': 'other'},
        {'version': 2},
        {'version': 1.0},
        {'frameUnit': 'm'},
        {'space': 'local'},
        {'pointer': 123},
        {'matrix': List.filled(16, 0)},
        {
          'pivotLocal': [double.nan, 0, 0],
        },
        {
          'operations': [
            {
              'kind': 'scale',
              'values': [1, 1, 1],
            },
          ],
        },
        {
          'operations': [
            {
              'kind': 'rotate',
              'values': [0, 0, 0, 0],
            },
          ],
        },
        {
          'operations': [
            {
              'kind': 'translate',
              'values': [0, double.infinity, 0],
            },
          ],
        },
      ]) {
        expect(
          () => EntityPlacement.fromJson({...json, ...update}),
          throwsFormatException,
        );
      }
      expect(
        () => EntityPlacement.validateRigidMatrix(Matrix4(List.filled(16, 0))),
        throwsFormatException,
      );
      expect(
        () => EntityPlacement.validateRigidMatrix(
          const Matrix4([2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
        ),
        throwsFormatException,
      );
      expect(
        () => EntityPlacement.identity([0, 0, 0]).rotate(0, 0, 0, 90),
        throwsFormatException,
      );
      expect(
        () => EntityPlacement.identity([
          0,
          0,
          0,
        ]).translate(double.infinity, 0, 0),
        throwsFormatException,
      );
    },
  );
  test('bounded stack and cumulative translation', () {
    var a = EntityPlacement.identity([0, 0, 0]);
    for (var i = 0; i < EntityPlacement.maxOperations; i++) {
      a = a.rotate(0, 0, 1, 1);
    }
    expect(() => a.translate(1, 0, 0), throwsFormatException);
    expect(
      () => EntityPlacement.identity([
        0,
        0,
        0,
      ]).translate(1e9, 0, 0).translate(1, 0, 0),
      throwsFormatException,
    );
  });
  test('version 1 migrates as identity; unknown document versions reject', () {
    final json = CadDocument.empty('p').toJson();
    expect(
      CadDocument.fromJson({...json, 'version': 1}).toJson()['version'],
      2,
    );
    expect(
      () => CadDocument.fromJson({...json, 'version': 99}),
      throwsFormatException,
    );
  });
  test(
    'presentation rotates normals and topological edges without modifying source',
    () {
      final local = <String, dynamic>{
        'nodes': [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0],
        'triangles': [0, 1, 2],
        'normals': [1.0, 0.0, 0.0],
        'bounds': [0.0, 0.0, 0.0, 1.0, 1.0, 0.0],
        'topologicalEdges': [
          [0.0, 0.0, 0.0, 1.0, 0.0, 0.0],
        ],
        'rootLinearRgb': [.1, .2, .3],
      };
      local['brepPresentation'] = Map<String, dynamic>.from(local);
      final before = jsonEncode(local);
      final p = projectManagedPlacement(
        local,
        EntityPlacement.identity([
          0,
          0,
          0,
        ]).rotate(0, 0, 1, 90).translate(10, 0, 0),
      );
      expect((p['nodes'] as List)[0], closeTo(10, 1e-10));
      expect((p['nodes'] as List)[4], closeTo(1, 1e-10));
      expect((p['normals'] as List)[0], closeTo(0, 1e-10));
      expect((p['normals'] as List)[1], closeTo(1, 1e-10));
      expect(
        p['topologicalEdges'],
        (p['brepPresentation'] as Map)['topologicalEdges'],
      );
      expect(p['rootLinearRgb'], local['rootLinearRgb']);
      expect(jsonEncode(local), before);
      expect((p['bounds'] as List)[0], closeTo(9, 1e-10));
    },
  );
}
