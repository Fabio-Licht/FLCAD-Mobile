enum FeatureConstraintType {
  dependsOn,
  symmetric,
  equalParameter,
  minDistance,
  maxDistance,
  manufacturingRule,
  inspectionRule,
}

class FeatureConstraint {
  const FeatureConstraint({
    required this.id,
    required this.type,
    required this.featureIds,
    this.parameters = const {},
    this.enabled = true,
  });
  final String id;
  final FeatureConstraintType type;
  final List<String> featureIds;
  final Map<String, dynamic> parameters;
  final bool enabled;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'featureIds': featureIds,
    'parameters': parameters,
    'enabled': enabled,
  };
}
