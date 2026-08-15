import '../models/surface_boundary_models.dart';

class SurfaceBoundaryWorkspace {
  const SurfaceBoundaryWorkspace(this.session);
  final SurfaceBoundarySession session;
  List<String> get panels => const [
    'Preview',
    'Boundary Analyzer',
    'Constraints',
    'Quality',
    'Validation',
    'Analytics',
    'Advisor',
    'Property Inspector',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Boundary Length':
        session.preview?.analysis.predictedLength ?? session.boundary.length,
    'Offset': session.parameters['offset'],
    'Rotation': session.parameters['rotation'],
    'Scale': session.parameters['scale'],
    'Direction': session.parameters['direction'],
    'Continuity': session.continuity.name.toUpperCase(),
    'Curvature': session.preview?.analysis.curvature,
    'Reflection': session.preview?.reflection,
    'Zebra': session.preview?.zebra,
    'Manufacturing Score': session.preview?.analysis.manufacturingScore,
    'Quality Prediction': session.preview?.analysis.quality,
    'Analytics': {
      'lengthChange': session.preview == null
          ? 0
          : session.preview!.analysis.predictedLength - session.boundary.length,
      'stress': session.preview?.analysis.stress,
      'twist': session.preview?.analysis.twist,
    },
  };
}
