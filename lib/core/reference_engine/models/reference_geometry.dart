import '../../smart_regions/models/geometry.dart';

sealed class ReferenceGeometry {
  const ReferenceGeometry();
  String get type;
  Map<String, dynamic> toJson();
}

class PlaneGeometry extends ReferenceGeometry {
  const PlaneGeometry(this.origin, this.normal, {this.xDirection});
  final Vec3 origin, normal;
  final Vec3? xDirection;
  @override
  String get type => 'plane';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'origin': origin.toJson(),
    'normal': normal.toJson(),
    'xDirection': xDirection?.toJson(),
  };
}

class AxisGeometry extends ReferenceGeometry {
  const AxisGeometry(this.origin, this.direction);
  final Vec3 origin, direction;
  @override
  String get type => 'axis';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'origin': origin.toJson(),
    'direction': direction.toJson(),
  };
}

class PointGeometry extends ReferenceGeometry {
  const PointGeometry(this.position);
  final Vec3 position;
  @override
  String get type => 'point';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'position': position.toJson(),
  };
}

class CurveGeometry extends ReferenceGeometry {
  const CurveGeometry(this.points, {this.closed = false});
  final List<Vec3> points;
  final bool closed;
  @override
  String get type => 'curve';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'points': points.map((e) => e.toJson()).toList(),
    'closed': closed,
  };
}

class CoordinateSystemGeometry extends ReferenceGeometry {
  const CoordinateSystemGeometry(
    this.origin,
    this.xAxis,
    this.yAxis,
    this.zAxis,
  );
  final Vec3 origin, xAxis, yAxis, zAxis;
  @override
  String get type => 'coordinateSystem';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'origin': origin.toJson(),
    'xAxis': xAxis.toJson(),
    'yAxis': yAxis.toJson(),
    'zAxis': zAxis.toJson(),
  };
}

ReferenceGeometry geometryFromJson(Map<String, dynamic> j) =>
    switch (j['type']) {
      'plane' => PlaneGeometry(
        Vec3.fromJson(j['origin'] as List),
        Vec3.fromJson(j['normal'] as List),
        xDirection: j['xDirection'] == null
            ? null
            : Vec3.fromJson(j['xDirection'] as List),
      ),
      'axis' => AxisGeometry(
        Vec3.fromJson(j['origin'] as List),
        Vec3.fromJson(j['direction'] as List),
      ),
      'point' => PointGeometry(Vec3.fromJson(j['position'] as List)),
      'curve' => CurveGeometry(
        (j['points'] as List).map((e) => Vec3.fromJson(e as List)).toList(),
        closed: j['closed'] as bool? ?? false,
      ),
      'coordinateSystem' => CoordinateSystemGeometry(
        Vec3.fromJson(j['origin'] as List),
        Vec3.fromJson(j['xAxis'] as List),
        Vec3.fromJson(j['yAxis'] as List),
        Vec3.fromJson(j['zAxis'] as List),
      ),
      _ => throw FormatException('Unknown reference geometry'),
    };
