import '../../smart_regions/models/geometry.dart';

enum SketchContextKind {
  plane,
  mesh,
  surface,
  region,
  cylinder,
  cone,
  sphere,
  torus,
  nurbs,
  hybrid,
}

class SketchGeometryContext {
  const SketchGeometryContext({
    required this.id,
    required this.kind,
    required this.sourceId,
    required this.fingerprint,
    this.metadata = const {},
  });

  final String id;
  final SketchContextKind kind;
  final String sourceId;
  final String fingerprint;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'sourceId': sourceId,
    'fingerprint': fingerprint,
    'metadata': metadata,
  };

  factory SketchGeometryContext.fromJson(Map<String, dynamic> json) =>
      SketchGeometryContext(
        id: json['id'] as String,
        kind: SketchContextKind.values.byName(json['kind'] as String),
        sourceId: json['sourceId'] as String,
        fingerprint: json['fingerprint'] as String,
        metadata: (json['metadata'] as Map? ?? const {}).cast(),
      );
}

class SketchAnchor {
  const SketchAnchor({
    required this.position,
    required this.contextId,
    this.surfaceCoordinates,
    this.primitiveIndex,
  });

  final Vec3 position;
  final String contextId;
  final List<double>? surfaceCoordinates;
  final int? primitiveIndex;

  Map<String, dynamic> toJson() => {
    'position': position.toJson(),
    'contextId': contextId,
    'surfaceCoordinates': surfaceCoordinates,
    'primitiveIndex': primitiveIndex,
  };

  factory SketchAnchor.fromJson(Map<String, dynamic> json) => SketchAnchor(
    position: Vec3.fromJson(json['position'] as List),
    contextId: json['contextId'] as String,
    surfaceCoordinates: (json['surfaceCoordinates'] as List?)
        ?.cast<num>()
        .map((value) => value.toDouble())
        .toList(),
    primitiveIndex: json['primitiveIndex'] as int?,
  );
}
