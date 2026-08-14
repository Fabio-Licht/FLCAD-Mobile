import '../models/live_reconstruction_models.dart';

class ReconstructionWorkspace {
  const ReconstructionWorkspace(this.value);
  final LiveReconstruction value;
  List<String> get panels => const [
    'Pipeline',
    'Affected Objects',
    'Live Updates',
    'Validation',
    'Analytics',
    'Timeline',
    'Advisor',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Pipeline State': value.state.name,
    'Dirty Objects': value.preview?.affected.all.length ?? 0,
    'Affected Patches': value.preview?.affected.patches.toList() ?? const [],
    'Affected Boundaries':
        value.preview?.affected.boundaries.toList() ?? const [],
    'Affected Continuity':
        value.preview?.affected.continuity.toList() ?? const [],
    'Affected Validation':
        value.preview?.affected.validation.toList() ?? const [],
    'Update Time': value.analytics.updateTime.inMicroseconds,
  };
}
