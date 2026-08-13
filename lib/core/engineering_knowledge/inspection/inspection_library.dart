import '../knowledge/knowledge_library.dart';
import '../models/knowledge_models.dart';

class InspectionKnowledgeLibrary {
  static const _p = KnowledgeProvenance(
    'FLCAD Inspection Knowledge',
    '0.7.0',
    verified: true,
  );
  static KnowledgeLibrary create() {
    KnowledgeConcept i(
      String id,
      String name,
      String category,
    ) => KnowledgeConcept(
      id: id,
      name: name,
      kind: 'inspectionCharacteristic',
      description:
          'Inspection concept; limits must come from the project or applicable standard',
      attributes: {'category': category},
      provenance: _p,
    );
    return KnowledgeLibrary([
      i('inspection.datum', 'Datum', 'reference'),
      i('inspection.size', 'Size tolerance', 'dimensional'),
      i('inspection.position', 'Position', 'location'),
      i('inspection.parallelism', 'Parallelism', 'orientation'),
      i('inspection.perpendicularity', 'Perpendicularity', 'orientation'),
      i('inspection.circularity', 'Circularity', 'form'),
    ]);
  }
}
