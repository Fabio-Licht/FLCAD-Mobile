import 'geometry.dart';

class RegionStatistics {
  const RegionStatistics({
    required this.area,
    required this.perimeter,
    required this.estimatedVolume,
    required this.averageCurvature,
    required this.averageNormal,
    required this.dominantType,
    required this.angularDistribution,
    required this.connectivity,
    required this.triangleCount,
    required this.vertexCount,
    required this.density,
    required this.centroid,
  });
  final double area, perimeter, estimatedVolume, averageCurvature, density;
  final Vec3 averageNormal, centroid;
  final String dominantType;
  final List<double> angularDistribution;
  final int connectivity, triangleCount, vertexCount;
  Map<String, dynamic> toJson() => {
    'area': area,
    'perimeter': perimeter,
    'estimatedVolume': estimatedVolume,
    'averageCurvature': averageCurvature,
    'averageNormal': averageNormal.toJson(),
    'dominantType': dominantType,
    'angularDistribution': angularDistribution,
    'connectivity': connectivity,
    'triangleCount': triangleCount,
    'vertexCount': vertexCount,
    'density': density,
    'centroid': centroid.toJson(),
  };
  factory RegionStatistics.fromJson(Map<String, dynamic> j) => RegionStatistics(
    area: (j['area'] as num).toDouble(),
    perimeter: (j['perimeter'] as num).toDouble(),
    estimatedVolume: (j['estimatedVolume'] as num).toDouble(),
    averageCurvature: (j['averageCurvature'] as num).toDouble(),
    averageNormal: Vec3.fromJson(j['averageNormal'] as List),
    dominantType: j['dominantType'] as String,
    angularDistribution: (j['angularDistribution'] as List)
        .cast<num>()
        .map((e) => e.toDouble())
        .toList(),
    connectivity: j['connectivity'] as int,
    triangleCount: j['triangleCount'] as int,
    vertexCount: j['vertexCount'] as int,
    density: (j['density'] as num).toDouble(),
    centroid: Vec3.fromJson(j['centroid'] as List),
  );
}
