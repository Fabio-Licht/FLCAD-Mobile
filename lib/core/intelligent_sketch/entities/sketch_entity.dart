import '../models/sketch_context.dart';

enum SketchEntityKind {
  line,
  arc,
  spline,
  polyline,
  rectangle,
  circle,
  ellipse,
  slot,
  text,
  point,
  freeCurve,
  guideCurve,
  averageCurve,
  projectedCurve,
  adaptiveCurve,
}

enum SketchEntityMode { staticEntity, live }

class SketchEntity {
  const SketchEntity({
    required this.id,
    required this.kind,
    required this.mode,
    required this.anchors,
    this.parameters = const {},
    this.sourceIds = const [],
    this.metadata = const {},
  });

  final String id;
  final SketchEntityKind kind;
  final SketchEntityMode mode;
  final List<SketchAnchor> anchors;
  final Map<String, double> parameters;
  final List<String> sourceIds;
  final Map<String, dynamic> metadata;

  SketchEntity copyWith({
    List<SketchAnchor>? anchors,
    Map<String, double>? parameters,
    Map<String, dynamic>? metadata,
  }) => SketchEntity(
    id: id,
    kind: kind,
    mode: mode,
    anchors: anchors ?? this.anchors,
    parameters: parameters ?? this.parameters,
    sourceIds: sourceIds,
    metadata: metadata ?? this.metadata,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'mode': mode.name,
    'anchors': anchors.map((anchor) => anchor.toJson()).toList(),
    'parameters': parameters,
    'sourceIds': sourceIds,
    'metadata': metadata,
  };

  factory SketchEntity.fromJson(Map<String, dynamic> json) => SketchEntity(
    id: json['id'] as String,
    kind: SketchEntityKind.values.byName(json['kind'] as String),
    mode: SketchEntityMode.values.byName(json['mode'] as String),
    anchors: (json['anchors'] as List)
        .map((value) => SketchAnchor.fromJson((value as Map).cast()))
        .toList(),
    parameters: (json['parameters'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, (value as num).toDouble()),
    ),
    sourceIds: (json['sourceIds'] as List? ?? const []).cast<String>(),
    metadata: (json['metadata'] as Map? ?? const {}).cast(),
  );
}
