enum SketchConstraintType {
  coincident,
  tangent,
  perpendicular,
  parallel,
  horizontal,
  vertical,
  concentric,
  collinear,
  offset,
  normal,
  onSurface,
  onMesh,
  onCurve,
  symmetric,
  equal,
  distance,
  angle,
  radius,
  diameter,
}

class SketchConstraint {
  const SketchConstraint({
    required this.id,
    required this.type,
    required this.entityIds,
    this.parameters = const {},
    this.enabled = true,
    this.priority = 0,
  });
  final String id;
  final SketchConstraintType type;
  final List<String> entityIds;
  final Map<String, double> parameters;
  final bool enabled;
  final int priority;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'entityIds': entityIds,
    'parameters': parameters,
    'enabled': enabled,
    'priority': priority,
  };
  factory SketchConstraint.fromJson(Map<String, dynamic> json) =>
      SketchConstraint(
        id: json['id'] as String,
        type: SketchConstraintType.values.byName(json['type'] as String),
        entityIds: (json['entityIds'] as List).cast<String>(),
        parameters: (json['parameters'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
        enabled: json['enabled'] as bool? ?? true,
        priority: json['priority'] as int? ?? 0,
      );
}
