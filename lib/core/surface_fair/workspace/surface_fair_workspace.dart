import '../models/surface_fair_models.dart';

class SurfaceFairWorkspace {
  const SurfaceFairWorkspace(this.session);
  final SurfaceFairSession session;
  List<String> get panels => const [
    'Preview',
    'Reflection',
    'Zebra',
    'Constraints',
    'Quality',
    'Validation',
    'Analytics',
    'Advisor',
    'Property Inspector',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Fair Strength': session.parameters['fairStrength'],
    'Relax Level': session.parameters['relaxLevel'],
    'Noise Reduction': session.parameters['noiseReduction'],
    'Twist': session.prediction?.twist,
    'Curvature': session.prediction?.curvature,
    'Reflection': session.prediction?.reflection,
    'Zebra': session.prediction?.zebra,
    'Manufacturing Score': session.prediction?.manufacturingScore,
    'Quality Prediction': session.prediction?.quality,
    'Analytics': {
      'surfaceEnergy': session.prediction?.surfaceEnergy,
      'stress': session.prediction?.stress,
      'affectedRegions': session.prediction?.affectedRegions.length ?? 0,
    },
  };
}
