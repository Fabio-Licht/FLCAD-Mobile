enum ReferenceConstraintType {
  parallel,
  perpendicular,
  coincident,
  tangent,
  concentric,
  fixedDistance,
  fixedAngle,
}

class ReferenceConstraint {
  const ReferenceConstraint({
    required this.id,
    required this.type,
    required this.referenceIds,
    required this.parameters,
    required this.enabled,
  });
  final String id;
  final ReferenceConstraintType type;
  final List<String> referenceIds;
  final Map<String, double> parameters;
  final bool enabled;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'referenceIds': referenceIds,
    'parameters': parameters,
    'enabled': enabled,
  };
}
