import '../../smart_regions/models/geometry.dart';

enum MeshLayerKind {
  original,
  alignment,
  cleaning,
  compensation,
  surfacePreparation,
  manufacturing,
  inspection,
  custom,
}

enum LayerBlendMode { replace, additive, maximum, minimum }

class MeshLayer {
  const MeshLayer({
    required this.id,
    required this.objectId,
    required this.name,
    required this.kind,
    required this.enabled,
    required this.locked,
    required this.opacity,
    required this.blendMode,
    required this.displacements,
    required this.createdAt,
    this.metadata = const {},
  });
  final String id, objectId, name;
  final MeshLayerKind kind;
  final bool enabled, locked;
  final double opacity;
  final LayerBlendMode blendMode;
  final Map<int, Vec3> displacements;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  MeshLayer copyWith({
    bool? enabled,
    bool? locked,
    double? opacity,
    Map<int, Vec3>? displacements,
  }) => MeshLayer(
    id: id,
    objectId: objectId,
    name: name,
    kind: kind,
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    opacity: opacity ?? this.opacity,
    blendMode: blendMode,
    displacements: displacements ?? this.displacements,
    createdAt: createdAt,
    metadata: metadata,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'objectId': objectId,
    'name': name,
    'kind': kind.name,
    'enabled': enabled,
    'locked': locked,
    'opacity': opacity,
    'blendMode': blendMode.name,
    'displacements': displacements.map((k, v) => MapEntry('$k', v.toJson())),
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };
  factory MeshLayer.fromJson(Map<String, dynamic> j) => MeshLayer(
    id: j['id'] as String,
    objectId: j['objectId'] as String,
    name: j['name'] as String,
    kind: MeshLayerKind.values.byName(j['kind'] as String),
    enabled: j['enabled'] as bool,
    locked: j['locked'] as bool,
    opacity: (j['opacity'] as num).toDouble(),
    blendMode: LayerBlendMode.values.byName(j['blendMode'] as String),
    displacements: (j['displacements'] as Map).map(
      (k, v) => MapEntry(int.parse(k as String), Vec3.fromJson(v as List)),
    ),
    createdAt: DateTime.parse(j['createdAt'] as String),
    metadata: (j['metadata'] as Map? ?? const {}).cast(),
  );
}

class MeshLayerStack {
  const MeshLayerStack(this.layers);
  final List<MeshLayer> layers;
  Map<int, Vec3> compose() {
    final result = <int, Vec3>{};
    for (final layer in layers.where((l) => l.enabled)) {
      for (final entry in layer.displacements.entries) {
        final scaled = Vec3(
          entry.value.x * layer.opacity,
          entry.value.y * layer.opacity,
          entry.value.z * layer.opacity,
        );
        result[entry.key] = switch (layer.blendMode) {
          LayerBlendMode.replace => scaled,
          LayerBlendMode.additive =>
            (result[entry.key] ?? const Vec3(0, 0, 0)) + scaled,
          LayerBlendMode.maximum => _max(result[entry.key], scaled),
          LayerBlendMode.minimum => _min(result[entry.key], scaled),
        };
      }
    }
    return result;
  }

  static Vec3 _max(Vec3? a, Vec3 b) => a == null
      ? b
      : Vec3(
          a.x.abs() > b.x.abs() ? a.x : b.x,
          a.y.abs() > b.y.abs() ? a.y : b.y,
          a.z.abs() > b.z.abs() ? a.z : b.z,
        );
  static Vec3 _min(Vec3? a, Vec3 b) => a == null
      ? b
      : Vec3(
          a.x.abs() < b.x.abs() ? a.x : b.x,
          a.y.abs() < b.y.abs() ? a.y : b.y,
          a.z.abs() < b.z.abs() ? a.z : b.z,
        );
}
