import '../models/surface_reduce_models.dart';

class SurfaceReduceWorkspace {
  const SurfaceReduceWorkspace(this.session);
  final SurfaceReduceSession session;
  List<String> get panels => const [
    'Preview',
    'Constraints',
    'Fixed Regions',
    'Analytics',
    'Advisor',
    'Validation',
    'Property Inspector',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Radius': session.parameters['radius'],
    'Target Radius': session.parameters['targetRadius'],
    'Reduction': session.parameters['reduction'],
    'Offset': session.parameters['offset'],
    'Direction': session.parameters['direction'],
    'Fixed Regions': session.fixedRegions.map((e) => e.toJson()).toList(),
    'Transition': session.transition.name.toUpperCase(),
    'Quality Prediction': session.prediction?.quality,
    'Manufacturing Score': session.prediction?.manufacturingScore,
    'Analytics': {
      'affectedRegions': session.prediction?.affectedRegions.length ?? 0,
      'stress': session.prediction?.stress,
      'twist': session.prediction?.twist,
    },
  };
}
