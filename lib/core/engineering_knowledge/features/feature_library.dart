import '../knowledge/knowledge_library.dart';
import '../models/knowledge_models.dart';

class FeatureKnowledgeLibrary {
  static const _p = KnowledgeProvenance(
    'FLCAD Feature Knowledge',
    '0.7.0',
    verified: true,
  );
  static KnowledgeLibrary create() {
    KnowledgeConcept f(
      String id,
      String name,
      String family,
      Map<String, dynamic> attributes,
      List<String> tags,
    ) => KnowledgeConcept(
      id: id,
      name: name,
      kind: 'feature',
      description: 'Structured $name engineering feature knowledge',
      attributes: {'family': family, ...attributes},
      provenance: _p,
      tags: tags,
    );
    return KnowledgeLibrary([
      f(
        'hole.through',
        'Through hole',
        'hole',
        {
          'requires': ['diameter'],
          'termination': 'through',
        },
        ['hole'],
      ),
      f(
        'hole.blind',
        'Blind hole',
        'hole',
        {
          'requires': ['diameter', 'depth'],
          'termination': 'blind',
        },
        ['hole'],
      ),
      f(
        'hole.counterbore',
        'Counterbored hole',
        'hole',
        {
          'requires': ['diameter', 'counterboreDiameter', 'counterboreDepth'],
        },
        ['hole', 'seat'],
      ),
      f(
        'hole.threaded',
        'Threaded hole',
        'hole',
        {
          'requires': ['nominalDiameter', 'threadDesignation', 'depth'],
        },
        ['hole', 'thread'],
      ),
      f(
        'hole.stepped',
        'Stepped hole',
        'hole',
        {
          'requires': ['diameters', 'stepDepths'],
        },
        ['hole'],
      ),
      f(
        'pocket.open',
        'Open pocket',
        'pocket',
        {
          'requires': ['depth'],
          'boundary': 'open',
        },
        ['pocket'],
      ),
      f(
        'pocket.closed',
        'Closed pocket',
        'pocket',
        {
          'requires': ['depth'],
          'boundary': 'closed',
        },
        ['pocket'],
      ),
      f(
        'slot.keyway',
        'Keyway',
        'slot',
        {
          'function': 'torqueTransfer',
          'requires': ['width', 'depth'],
        },
        ['slot', 'shaft'],
      ),
      f(
        'slot.t',
        'T-slot',
        'slot',
        {
          'requires': ['neckWidth', 'baseWidth', 'depth'],
        },
        ['slot'],
      ),
      f(
        'slot.dovetail',
        'Dovetail slot',
        'slot',
        {
          'requires': ['angle', 'depth', 'width'],
        },
        ['slot'],
      ),
      f(
        'slot.oilGroove',
        'Oil groove',
        'slot',
        {'function': 'lubrication'},
        ['slot'],
      ),
      f(
        'rib',
        'Rib',
        'reinforcement',
        {'function': 'stiffness'},
        ['reinforcement'],
      ),
      f(
        'flange',
        'Flange',
        'interface',
        {'function': 'mounting'},
        ['interface'],
      ),
      f(
        'boss',
        'Boss',
        'interface',
        {'function': 'localSupport'},
        ['interface'],
      ),
      f(
        'guide',
        'Guide',
        'motion',
        {'function': 'constrainedMotion'},
        ['motion'],
      ),
      f(
        'housing.bearing',
        'Bearing housing',
        'housing',
        {
          'requires': ['seatDiameter', 'axis', 'toleranceClass'],
          'function': 'supportBearing',
        },
        ['housing', 'bearing'],
      ),
      f(
        'seat.bearing',
        'Bearing seat',
        'seat',
        {
          'requires': ['diameter', 'axis', 'tolerance'],
          'function': 'locateBearing',
        },
        ['seat', 'bearing'],
      ),
      f(
        'reinforcement',
        'Reinforcement',
        'reinforcement',
        {'function': 'loadDistribution'},
        ['reinforcement'],
      ),
    ]);
  }
}
