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
      'strategy': node.context['strategy'],
      'predictedContinuity': node.context['predictedContinuity'],
      'justification': node.context['justification'],
      'regions': node.context['regions'],
      'alternatives': node.context['alternatives'],
      'surfaceScore': node.context['surfaceScore'],
      'surfaceType': node.context['surfaceType'],
      'evidence': node.context['evidence'],
      'revision': node.context['revision'],
      'hybridStrategy': node.context['hybridStrategy'],
      'neighbors': node.context['neighbors'],
      'selectedAlternative': node.context['selectedAlternative'],
      'discardedAlternatives': node.context['discardedAlternatives'],
      'topoDSType': node.context['topoDSType'],
      'kernelId': node.context['kernelId'],
      'kernelVersion': node.context['kernelVersion'],
      'kernelCapabilities': node.context['kernelCapabilities'],
      'nativeDiagnostics': node.context['nativeDiagnostics'],
    }),
    if (node.type.name == 'sketch')
      PropertySection('Sketch', {
        'persistentId': node.context['persistentId'],
        'entityType': node.context['entityType'],
        'plane': node.context['plane'],
        'coordinates': node.context['coordinates'],
        'construction': node.context['construction'],
        'reference': node.context['reference'],
        'visibility': node.visible,
        'lock': node.locked,
        'diagnostics': node.context['diagnostics'],
      }),
    if (node.context['constraintType'] != null)
      PropertySection('Constraint', {
        'constraintType': node.context['constraintType'],
        'status': node.context['status'],
        'driving': node.context['driving'],
        'driven': node.context['driven'],
        'priority': node.context['priority'],
        'solved': node.context['solved'],
        'references': node.context['references'],
        'diagnostics': node.context['diagnostics'],
        'timestamp': node.context['timestamp'],
        'persistentId': node.context['persistentId'],
      }),
    if (node.context['editorEntity'] == true)
      PropertySection('Sketch Editor', {
        'coordinates': node.context['coordinates'],
        'length': node.context['length'],
        'radius': node.context['radius'],
        'diameter': node.context['diameter'],
        'angle': node.context['angle'],
        'construction': node.context['construction'],
        'reference': node.context['reference'],
        'driving': node.context['driving'],
        'driven': node.context['driven'],
        'constraintCount': node.context['constraintCount'],
        'degreesOfFreedom': node.context['degreesOfFreedom'],
        'selectionState': node.context['selectionState'],
        'persistentId': node.context['persistentId'],
        'history': node.context['history'],
        'diagnostics': node.context['diagnostics'],
      }),
    if (node.context['profileRecognition'] == true)
      PropertySection('Profile Recognition', {
        'profileType': node.context['profileType'],
        'loopCount': node.context['loopCount'],
        'regionCount': node.context['regionCount'],
        'area': node.context['area'],
        'perimeter': node.context['perimeter'],
        'orientation': node.context['orientation'],
        'topologyStatus': node.context['topologyStatus'],
        'readiness': node.context['readiness'],
        'quality': node.context['quality'],
        'intent': node.context['intent'],
        'confidence': node.context['confidence'],
        'persistentId': node.context['persistentId'],
      }),
    PropertySection(
      'Analytics',
      (node.context['analytics'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  ];
}
