import '../models/surface_morph_models.dart';

class SurfaceMorphWorkspace {
  const SurfaceMorphWorkspace(this.session);
  final MorphSession session;
  List<String> get panels => const [
    'Morph Tree',
    'Anchors',
    'Constraints',
    'Preview',
    'Validation',
    'Analytics',
    'History',
    'Advisor',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Morph Tool': session.tool.name,
    'Anchor Count': session.anchors.length,
    'Influence Radius': session.radius,
    'Falloff Type': session.falloff.name,
    'Constraint Groups': session.constraintGroups.length,
    'Validation Status': session.validation?.valid,
    'Preview Status': session.preview == null ? 'Not Created' : 'Ready',
  };
}
