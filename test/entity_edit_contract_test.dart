import 'package:flcad_mobile/app/modeling/entity_edit_contract.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'authored entities use one permanent double-click re-entry contract',
    () {
      const sketch = CadDocumentEntity(
        id: 'sketch:001',
        kind: CadDocumentEntityKind.sketch,
        data: {'sketch': <String, dynamic>{}},
      );
      const futureTopologyFeature = CadDocumentEntity(
        id: 'feature:001',
        kind: CadDocumentEntityKind.face,
        data: {'authoringRoot': true, 'authoringWorkspace': 'Topology'},
      );

      expect(EntityEditContract.activationGesture, 'doubleClick');
      expect(EntityEditContract.isAuthoringRoot(sketch), isTrue);
      expect(EntityEditContract.workspace(sketch), 'Sketch');
      expect(EntityEditContract.isAuthoringRoot(futureTopologyFeature), isTrue);
      expect(EntityEditContract.workspace(futureTopologyFeature), 'Topology');
    },
  );
}
