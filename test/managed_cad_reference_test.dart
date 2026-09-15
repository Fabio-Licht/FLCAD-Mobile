import 'dart:convert';

import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_document/managed_cad_reference.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reference = ManagedCadReference.plane(
    sourceEntityId: 'managed-step:part',
    sourceFormat: 'step',
    sourceShapeSha256:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    faceIndex: 3,
    origin: Vector3(1, 2, 3),
    normal: Vector3(0, 0, 1),
    xDirection: Vector3(1, 0, 0),
  );

  test('managed CAD reference v1 round-trips as durable document data', () {
    final entity = CadDocumentEntity(
      id: 'managed-plane:1',
      kind: CadDocumentEntityKind.reference,
      data: {
        'name': 'Plano part F3',
        ManagedCadReference.dataKey: reference.toJson(),
      },
    );
    final decoded = CadDocumentEntity.fromJson(
      jsonDecode(jsonEncode(entity.toJson())) as Map<String, dynamic>,
    );
    final restored = ManagedCadReference.fromJson(
      Map<String, dynamic>.from(
        decoded.data[ManagedCadReference.dataKey] as Map,
      ),
    );
    expect(restored.sourceEntityId, reference.sourceEntityId);
    expect(restored.faceIndex, 3);
    expect(restored.origin.toJson(), [1.0, 2.0, 3.0]);
  });

  test('transient native and filesystem identity cannot be persisted', () {
    for (final forbidden in ['token', 'pointer', 'pathname']) {
      final raw = reference.toJson()..[forbidden] = 'forbidden';
      expect(
        () => ManagedCadReference.fromJson(raw),
        throwsFormatException,
        reason: forbidden,
      );
    }
    expect(
      () => CadDocumentEntity.fromJson({
        'id': 'bad',
        'kind': 'import',
        'data': {ManagedCadReference.dataKey: reference.toJson()},
        'shape': null,
        'mesh': null,
      }),
      throwsFormatException,
    );
  });

  test('cylindrical axis is normalized, canonical and durable', () {
    const axis = ManagedCadReference.cylindricalAxis(
      sourceEntityId: 'managed-brep:cylinder',
      sourceFormat: 'brep',
      sourceShapeSha256:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      faceIndex: 7,
      origin: Vector3(4, 5, 6),
      direction: Vector3(0, 0, -2),
      radius: 3,
    );
    final restored = ManagedCadReference.fromJson(axis.toJson());
    expect((axis.toJson()['geometry'] as Map)['direction'], [0.0, 0.0, 1.0]);
    expect(restored.kind, ManagedCadReferenceKind.cylindricalAxis);
    expect(restored.direction!.toJson(), [0.0, 0.0, 1.0]);
    expect(restored.direction!.length, closeTo(1, 1e-12));
    expect(restored.radius, 3);
    expect(restored.toJson()['geometry'], {
      'space': 'world',
      'origin': [4.0, 5.0, 6.0],
      'direction': [0.0, 0.0, 1.0],
      'radius': 3.0,
    });
  });

  test('cylindrical axis rejects invalid geometry and transient fields', () {
    const hash =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
    Map<String, dynamic> valid() => const ManagedCadReference.cylindricalAxis(
      sourceEntityId: 'source',
      sourceFormat: 'step',
      sourceShapeSha256: hash,
      faceIndex: 1,
      origin: Vector3.zero,
      direction: Vector3(1, 0, 0),
      radius: 2,
    ).toJson();
    for (final invalid in [
      (valid()..['primitiveId'] = 4),
      (valid()..['pathname'] = r'C:\part.step'),
      (valid()..['token'] = 'native'),
      (valid()..['geometry'] = {...valid()['geometry'] as Map, 'radius': 0}),
      (valid()
        ..['geometry'] = {
          ...valid()['geometry'] as Map,
          'direction': [0, 0, 0],
        }),
    ]) {
      expect(
        () => ManagedCadReference.fromJson(invalid),
        throwsFormatException,
      );
    }
  });
}
