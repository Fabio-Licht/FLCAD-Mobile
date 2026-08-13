import '../knowledge/knowledge_library.dart';
import '../models/knowledge_models.dart';

class ManufacturingKnowledgeLibrary {
  static const _p = KnowledgeProvenance(
    'FLCAD Manufacturing Knowledge',
    '0.7.0',
    verified: true,
  );
  static KnowledgeLibrary create() {
    KnowledgeConcept p(
      String id,
      String name,
      Map<String, dynamic> attributes,
      List<String> tags,
    ) => KnowledgeConcept(
      id: id,
      name: name,
      kind: 'manufacturingProcess',
      description: 'Process constraints requiring project-specific validation',
      attributes: attributes,
      provenance: _p,
      tags: tags,
    );
    return KnowledgeLibrary([
      p(
        'process.cnc',
        'CNC machining',
        {
          'considerations': [
            'toolAccess',
            'minimumInternalRadius',
            'depthToDiameter',
            'sharpCorners',
          ],
        },
        ['machining'],
      ),
      p(
        'process.casting',
        'Casting',
        {
          'considerations': ['draft', 'shrinkage', 'fillets', 'partingLine'],
        },
        ['casting'],
      ),
      p(
        'process.injection',
        'Injection molding',
        {
          'considerations': [
            'wallThickness',
            'draft',
            'partingLine',
            'ejection',
          ],
        },
        ['molding'],
      ),
      p(
        'process.additive',
        'Additive manufacturing',
        {
          'considerations': ['overhang', 'bridges', 'anisotropy', 'supports'],
        },
        ['additive'],
      ),
      p(
        'process.sheetMetal',
        'Sheet metal forming',
        {
          'considerations': [
            'bendRadius',
            'grainDirection',
            'springback',
            'unfolding',
          ],
        },
        ['forming'],
      ),
      p(
        'process.forging',
        'Forging',
        {
          'considerations': [
            'draft',
            'grainFlow',
            'flash',
            'machiningAllowance',
          ],
        },
        ['forging'],
      ),
      p(
        'process.welding',
        'Welding',
        {
          'considerations': [
            'jointAccess',
            'distortion',
            'heatAffectedZone',
            'inspection',
          ],
        },
        ['welding'],
      ),
    ]);
  }
}
