class RegionDNA {
  const RegionDNA({
    required this.normalHistogram,
    required this.curvatureHistogram,
    required this.topologySignature,
    required this.area,
    required this.perimeter,
    required this.connectivity,
    required this.centroid,
    required this.hash,
  });
  final List<double> normalHistogram, curvatureHistogram, centroid;
  final String topologySignature, hash;
  final double area, perimeter;
  final int connectivity;
  Map<String, dynamic> toJson() => {
    'normalHistogram': normalHistogram,
    'curvatureHistogram': curvatureHistogram,
    'topologySignature': topologySignature,
    'area': area,
    'perimeter': perimeter,
    'connectivity': connectivity,
    'centroid': centroid,
    'hash': hash,
  };
  factory RegionDNA.fromJson(Map<String, dynamic> j) => RegionDNA(
    normalHistogram: (j['normalHistogram'] as List)
        .cast<num>()
        .map((e) => e.toDouble())
        .toList(),
    curvatureHistogram: (j['curvatureHistogram'] as List)
        .cast<num>()
        .map((e) => e.toDouble())
        .toList(),
    topologySignature: j['topologySignature'] as String,
    area: (j['area'] as num).toDouble(),
    perimeter: (j['perimeter'] as num).toDouble(),
    connectivity: j['connectivity'] as int,
    centroid: (j['centroid'] as List)
        .cast<num>()
        .map((e) => e.toDouble())
        .toList(),
    hash: j['hash'] as String,
  );
}
