import 'package:flcad_mobile/app/desktop/explorer_tree_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'opened project projects empty Explorer workspaces without placeholder rows',
    () {
      final groups = <String, List<String>>{
        'Curves': [],
        'Surfaces': [],
        'Reference Curves': [],
        'Inspection': [],
        'Solids': ['Extrude 1'],
        'Construction': ['Construction Plane 1'],
      };

      for (final name in [
        'Curves',
        'Surfaces',
        'Reference Curves',
        'Inspection',
      ]) {
        expect(ExplorerTreeProjection.rowsFor(groups[name]!), isEmpty);
      }
      expect(ExplorerTreeProjection.rowsFor(groups['Solids']!), ['Extrude 1']);
      expect(ExplorerTreeProjection.rowsFor(groups['Construction']!), [
        'Construction Plane 1',
      ]);
    },
  );
}
