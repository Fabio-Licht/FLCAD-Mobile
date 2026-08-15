import '../context/engineering_context.dart';

class EngineeringFeatureVector {
  EngineeringFeatureVector(Map<String, double> values)
    : values = Map.unmodifiable(values);
  final Map<String, double> values;
  double operator [](String key) => values[key] ?? 0;
  Map<String, dynamic> toJson() => values;
}

class FeatureVectorBuilder {
  const FeatureVectorBuilder();
  EngineeringFeatureVector build(EngineeringContext context) {
    double metric(String key) => context.metrics[key] ?? 0;
    return EngineeringFeatureVector({
      'planes': context.planes.length.toDouble(),
      'cylinders': metric('cylinders'),
      'cones': metric('cones'),
      'spheres': metric('spheres'),
      'tori': metric('tori'),
      'patches': context.patches.length.toDouble(),
      'boundaries': context.boundaries.length.toDouble(),
      'loops': metric('loops'),
      'continuity': metric('continuity'),
      'curvature': metric('curvature'),
      'area': metric('area'),
      'availableVolume': metric('availableVolume'),
      'symmetry': metric('symmetry'),
      'patterns': metric('patterns'),
      'spatialDistribution': metric('spatialDistribution'),
    });
  }
}
