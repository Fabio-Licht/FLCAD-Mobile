import '../models/advanced_surface_models.dart';

class AdvancedSurfaceWorkspace {
  const AdvancedSurfaceWorkspace(this.session);
  final AdvancedSurfaceSession session;
  List<String> get panels => const [
    'Preview',
    'Gap Analysis',
    'Network Analysis',
    'Constraints',
    'Validation',
    'Analytics',
    'Advisor',
    'Property Inspector',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Surface Degree': session.parameters['degree'],
    'Surface Spans': session.parameters['spans'],
    'Match Mode': session.type == AdvancedSurfaceType.match
        ? session.continuity.name.toUpperCase()
        : null,
    'Fill Mode':
        session.type == AdvancedSurfaceType.fill ||
            session.type == AdvancedSurfaceType.boundaryFill
        ? session.continuity.name.toUpperCase()
        : null,
    'Stitch Tolerance': session.parameters['stitchTolerance'],
    'Healing Tolerance': session.parameters['healingTolerance'],
    'Network Quality': session.preview?.networkAnalysis.globalQuality,
    'Reflection': session.preview?.networkAnalysis.reflection,
    'Zebra': session.preview?.networkAnalysis.zebra,
    'Manufacturing Score': session.preview?.networkAnalysis.manufacturingScore,
    'Analytics': {
      'affectedSurfaces': session.preview?.affectedSurfaces.length ?? 0,
      'gaps': session.preview?.gapAnalysis.gaps.length ?? 0,
    },
  };
}
