import '../knowledge/knowledge_library.dart';
import '../models/knowledge_models.dart';

class MaterialKnowledgeLibrary {
  static const _p = KnowledgeProvenance(
    'FLCAD Material Knowledge',
    '0.7.0',
    verified: true,
  );
  static KnowledgeLibrary create() {
    KnowledgeConcept m(
      String id,
      String name,
      List<String> processes,
      List<String> considerations,
    ) => KnowledgeConcept(
      id: id,
      name: name,
      kind: 'materialFamily',
      description:
          'Material-family guidance; grade-specific properties are required for calculations',
      attributes: {
        'compatibleProcesses': processes,
        'considerations': considerations,
      },
      provenance: _p,
    );
    return KnowledgeLibrary([
      m(
        'material.aluminum',
        'Aluminum',
        ['process.cnc', 'process.casting', 'process.additive'],
        ['alloy', 'heatTreatment'],
      ),
      m(
        'material.steel',
        'Steel',
        ['process.cnc', 'process.forging', 'process.welding'],
        ['grade', 'hardness'],
      ),
      m(
        'material.castIron',
        'Cast iron',
        ['process.casting', 'process.cnc'],
        ['grade', 'graphiteStructure'],
      ),
      m(
        'material.stainless',
        'Stainless steel',
        ['process.cnc', 'process.sheetMetal', 'process.welding'],
        ['grade', 'workHardening'],
      ),
      m(
        'material.polymer',
        'Polymer',
        ['process.injection', 'process.additive'],
        ['resin', 'temperature'],
      ),
      m(
        'material.titanium',
        'Titanium',
        ['process.cnc', 'process.forging', 'process.additive'],
        ['grade', 'heatInput'],
      ),
    ]);
  }
}
