import '../models/surface_extend_models.dart';

class SurfaceExtendWorkspace {
  const SurfaceExtendWorkspace(this.session);
  final ExtendSession session;
  List<String> get panels => const [
    'Extend Manager',
    'Extend Analyzer',
    'Anchors',
    'Preview',
    'Validation',
    'Analytics',
    'History',
    'Advisor',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Extend Type': session.type.name,
    'Distance': session.analysis?.distance,
    'Angle': session.analysis?.angle,
    'Vector': session.analysis?.direction,
    'Draft Direction': session.parameters['draftDirection'],
    'Manufacturing Intent': session.manufacturingIntent,
    'Predicted Quality': session.analysis?.estimatedQuality,
    'Predicted Reflection': session.analysis?.reflectionScore,
    'Predicted Zebra': session.analysis?.zebraScore,
    'Predicted Twist': session.analysis?.twistRisk,
  };
}
