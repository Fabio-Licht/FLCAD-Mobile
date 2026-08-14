import '../models/surface_operation_models.dart';

class SurfaceOperationsWorkspace {
  SurfaceOperationsWorkspace(this.operation);
  final SurfaceOperation operation;
  List<String> get panels => const [
    'Operations Tree',
    'Constraint Inspector',
    'Preview',
    'Validation',
    'Analytics',
    'History',
    'Advisor',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Operation Type': operation.type.name,
    'Execution Status': operation.status.name,
    'Constraint Count': operation.constraints.length,
    'Validation Result': operation.validation?.valid,
    'Affected Patches': operation.preview?.affectedPatches ?? const [],
    'Affected Boundaries': operation.preview?.affectedBoundaries ?? const [],
    'Affected Continuity': operation.preview?.affectedContinuity ?? const [],
  };
}
