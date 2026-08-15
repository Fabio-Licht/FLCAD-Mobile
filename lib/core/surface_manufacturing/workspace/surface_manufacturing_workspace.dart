import '../models/surface_manufacturing_models.dart';

class SurfaceManufacturingWorkspace {
  const SurfaceManufacturingWorkspace(this.session);
  final SurfaceManufacturingSession session;
  List<String> get panels => const [
    'Draft Analysis',
    'Manufacturing Analyzer',
    'Preview',
    'Constraints',
    'Validation',
    'Analytics',
    'Advisor',
    'Property Inspector',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Draft Angle': session.parameters['draftAngle'],
    'Draft Direction': session.parameters['draftDirection'],
    'Extension Angle': session.parameters['extensionAngle'],
    'Manufacturing Offset': session.parameters['offset'],
    'Punch Extension': session.type == ManufacturingOperationType.punchExtension
        ? session.parameters
        : null,
    'Die Extension': session.type == ManufacturingOperationType.dieExtension
        ? session.parameters
        : null,
    'Machining Score': session.preview?.analysis.machiningScore,
    'Stamping Score': session.preview?.analysis.stampingScore,
    'Mold Score': session.preview?.analysis.moldScore,
    'Manufacturing Quality': session.preview?.analysis.quality,
    'Analytics': session.preview?.strategyImpact,
  };
}
