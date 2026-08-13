import '../models/studio_models.dart';

class PropertySection {
  const PropertySection(this.name, this.values);
  final String name;
  final Map<String, dynamic> values;
}

class PropertyInspector {
  const PropertyInspector();
  List<PropertySection> inspect(EngineeringTreeNode node) => [
    PropertySection('Identity', {
      'id': node.id,
      'name': node.name,
      'type': node.type.name,
      'status': node.status,
    }),
    PropertySection('Engineering', {
      'confidence': node.confidence,
      'visible': node.visible,
      'locked': node.locked,
      'origin': node.context['origin'],
      'normal': node.context['normal'],
      'area': node.context['area'],
      'dna': node.context['dna'],
      'dependencies': node.context['dependencies'],
      'persistentId': node.context['persistentId'],
      'valid': node.context['valid'],
      'diagnostics': node.context['diagnostics'],
      'featureId': node.context['featureId'],
      'parameters': node.context['parameters'],
      'shapeHandle': node.context['shapeHandle'],
      'persistentIds': node.context['persistentIds'],
      'history': node.context['history'],
      'buildTimeMicros': node.context['buildTimeMicros'],
    }),
    PropertySection(
      'Analytics',
      (node.context['analytics'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  ];
}
