enum TopologyConstraintType {
  frozen,
  maxDisplacement,
  normalOnly,
  preserveRadius,
  preserveBoundary,
  preserveThickness,
  preserveFeature,
  preserveVolume,
}

class TopologyConstraint {
  const TopologyConstraint({
    required this.id,
    required this.type,
    required this.vertexIndices,
    this.parameters = const {},
    this.enabled = true,
  });
  final String id;
  final TopologyConstraintType type;
  final Set<int> vertexIndices;
  final Map<String, double> parameters;
  final bool enabled;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'vertexIndices': vertexIndices.toList(),
    'parameters': parameters,
    'enabled': enabled,
  };
  factory TopologyConstraint.fromJson(Map<String, dynamic> j) =>
      TopologyConstraint(
        id: j['id'] as String,
        type: TopologyConstraintType.values.byName(j['type'] as String),
        vertexIndices: (j['vertexIndices'] as List).cast<int>().toSet(),
        parameters: (j['parameters'] as Map? ?? const {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        enabled: j['enabled'] as bool? ?? true,
      );
}
