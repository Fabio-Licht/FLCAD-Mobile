import 'dart:math' as math;

import '../../utils/id_generator.dart';

class SketchVector {
  const SketchVector(this.x, this.y, [this.z = 0]);
  final double x;
  final double y;
  final double z;

  SketchVector operator +(SketchVector other) =>
      SketchVector(x + other.x, y + other.y, z + other.z);
  SketchVector operator -(SketchVector other) =>
      SketchVector(x - other.x, y - other.y, z - other.z);
  SketchVector scale(double value) =>
      SketchVector(x * value, y * value, z * value);
  double dot(SketchVector other) => x * other.x + y * other.y + z * other.z;
  List<double> toJson() => [x, y, z];
  static SketchVector fromJson(Object? value) {
    final v = (value as List).cast<num>();
    return SketchVector(v[0].toDouble(), v[1].toDouble(), v[2].toDouble());
  }
}

enum SketchPlaneType {
  xy,
  yz,
  zx,
  faceReference,
  custom,
  offset,
  threePoints,
  normalToEdge,
  throughAxis,
}

class SketchPlane {
  SketchPlane({
    required this.type,
    Map<String, dynamic>? parameters,
    String? id,
  }) : id = id ?? 'plane:${IdGenerator.generate()}',
       parameters = parameters ?? <String, dynamic>{};

  final String id;
  final SketchPlaneType type;
  final Map<String, dynamic> parameters;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'parameters': parameters,
  };
  factory SketchPlane.fromJson(Map<String, dynamic> json) => SketchPlane(
    id: json['id'] as String,
    type: SketchPlaneType.values.byName(json['type'] as String),
    parameters: (json['parameters'] as Map).cast<String, dynamic>(),
  );
}

class SketchCoordinateSystem {
  const SketchCoordinateSystem({
    this.origin = const SketchVector(0, 0, 0),
    this.xAxis = const SketchVector(1, 0, 0),
    this.yAxis = const SketchVector(0, 1, 0),
    this.normal = const SketchVector(0, 0, 1),
  });
  final SketchVector origin;
  final SketchVector xAxis;
  final SketchVector yAxis;
  final SketchVector normal;

  List<double> get transformMatrix => [
    xAxis.x,
    yAxis.x,
    normal.x,
    origin.x,
    xAxis.y,
    yAxis.y,
    normal.y,
    origin.y,
    xAxis.z,
    yAxis.z,
    normal.z,
    origin.z,
    0,
    0,
    0,
    1,
  ];
  SketchVector localToGlobal(SketchVector local) =>
      origin +
      xAxis.scale(local.x) +
      yAxis.scale(local.y) +
      normal.scale(local.z);
  SketchVector globalToLocal(SketchVector global) {
    final delta = global - origin;
    return SketchVector(delta.dot(xAxis), delta.dot(yAxis), delta.dot(normal));
  }

  SketchCoordinateSystem translate(SketchVector delta) =>
      SketchCoordinateSystem(
        origin: origin + delta,
        xAxis: xAxis,
        yAxis: yAxis,
        normal: normal,
      );
  SketchCoordinateSystem scale(double factor) => SketchCoordinateSystem(
    origin: origin,
    xAxis: xAxis.scale(factor),
    yAxis: yAxis.scale(factor),
    normal: normal,
  );
  SketchCoordinateSystem rotate(double radians) {
    final c = math.cos(radians), s = math.sin(radians);
    return SketchCoordinateSystem(
      origin: origin,
      xAxis: SketchVector(
        xAxis.x * c - xAxis.y * s,
        xAxis.x * s + xAxis.y * c,
        xAxis.z,
      ),
      yAxis: SketchVector(
        yAxis.x * c - yAxis.y * s,
        yAxis.x * s + yAxis.y * c,
        yAxis.z,
      ),
      normal: normal,
    );
  }

  SketchCoordinateSystem mirror() => SketchCoordinateSystem(
    origin: origin,
    xAxis: xAxis.scale(-1),
    yAxis: yAxis,
    normal: normal.scale(-1),
  );
  Map<String, dynamic> toJson() => {
    'origin': origin.toJson(),
    'xAxis': xAxis.toJson(),
    'yAxis': yAxis.toJson(),
    'normal': normal.toJson(),
  };
  factory SketchCoordinateSystem.fromJson(Map<String, dynamic> json) =>
      SketchCoordinateSystem(
        origin: SketchVector.fromJson(json['origin']),
        xAxis: SketchVector.fromJson(json['xAxis']),
        yAxis: SketchVector.fromJson(json['yAxis']),
        normal: SketchVector.fromJson(json['normal']),
      );
}

class Sketch {
  Sketch({
    required this.name,
    SketchPlane? plane,
    SketchCoordinateSystem? coordinates,
    this.owner = 'local',
    String? id,
    DateTime? timestamp,
    this.version = 1,
    List<String>? entityIds,
    Map<String, dynamic>? metadata,
  }) : id = id ?? 'sketch:${IdGenerator.generate()}',
       timestamp = timestamp ?? DateTime.now().toUtc(),
       plane = plane ?? SketchPlane(type: SketchPlaneType.xy),
       coordinates = coordinates ?? const SketchCoordinateSystem(),
       entityIds = entityIds ?? <String>[],
       metadata = metadata ?? <String, dynamic>{};
  final String id;
  String name;
  final String owner;
  final DateTime timestamp;
  int version;
  final SketchPlane plane;
  final SketchCoordinateSystem coordinates;
  final List<String> entityIds;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner': owner,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'plane': plane.toJson(),
    'coordinates': coordinates.toJson(),
    'entityIds': entityIds,
    'metadata': metadata,
  };
  factory Sketch.fromJson(Map<String, dynamic> j) => Sketch(
    id: j['id'] as String,
    name: j['name'] as String,
    owner: j['owner'] as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
    version: j['version'] as int,
    plane: SketchPlane.fromJson((j['plane'] as Map).cast<String, dynamic>()),
    coordinates: SketchCoordinateSystem.fromJson(
      (j['coordinates'] as Map).cast<String, dynamic>(),
    ),
    entityIds: (j['entityIds'] as List).cast<String>(),
    metadata: (j['metadata'] as Map).cast<String, dynamic>(),
  );
}
