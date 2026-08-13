import '../../smart_regions/models/geometry.dart';

enum SurfaceKind {
  plane,
  cylinder,
  cone,
  sphere,
  torus,
  nurbs,
  bezier,
  bSpline,
  sweep,
  loft,
  fill,
  patch,
  extrusion,
  revolution,
  offset,
  blend,
  bridge,
  coons,
  gordon,
  subdivision,
  freeform,
}

sealed class SurfaceGeometry {
  const SurfaceGeometry();
  SurfaceKind get kind;
  Map<String, dynamic> toJson();
}

class ParametricSurfaceGeometry extends SurfaceGeometry {
  const ParametricSurfaceGeometry(
    this.kind,
    this.parameters, {
    this.controlPoints = const [],
    this.degreeU = 1,
    this.degreeV = 1,
  });
  @override
  final SurfaceKind kind;
  final Map<String, double> parameters;
  final List<Vec3> controlPoints;
  final int degreeU, degreeV;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'parameters': parameters,
    'controlPoints': controlPoints.map((p) => p.toJson()).toList(),
    'degreeU': degreeU,
    'degreeV': degreeV,
  };
  factory ParametricSurfaceGeometry.fromJson(Map<String, dynamic> j) =>
      ParametricSurfaceGeometry(
        SurfaceKind.values.byName(j['kind'] as String),
        (j['parameters'] as Map? ?? const {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        controlPoints: (j['controlPoints'] as List? ?? const [])
            .map((p) => Vec3.fromJson(p as List))
            .toList(),
        degreeU: j['degreeU'] as int? ?? 1,
        degreeV: j['degreeV'] as int? ?? 1,
      );
}
