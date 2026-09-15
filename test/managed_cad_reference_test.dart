import 'dart:convert';

import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_document/managed_cad_reference.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reference = ManagedCadReference(
    kind: ManagedCadReferenceKind.plane,
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
}
