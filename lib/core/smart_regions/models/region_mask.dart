class RegionMask {
  const RegionMask({
    required this.id,
    required this.regionId,
    required this.type,
    required this.values,
    required this.metadata,
  });
  final String id, regionId, type;
  final Map<int, double> values;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> toJson() => {
    'id': id,
    'regionId': regionId,
    'type': type,
    'values': values.map((k, v) => MapEntry('$k', v)),
    'metadata': metadata,
  };
}
