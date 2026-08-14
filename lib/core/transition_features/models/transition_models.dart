import '../../cad_kernel/models/kernel_models.dart';
import '../../utils/id_generator.dart';

enum TransitionFamily { sweep, loft }

enum SweepType {
  boss,
  cut,
  thin,
  surface,
  multiProfile,
  multiPath,
  guide,
  compositePath,
}

enum LoftType {
  solid,
  surface,
  thin,
  multiSection,
  guideCurve,
  centerline,
  boundary,
  closed,
}

enum TransitionStatus {
  prepared,
  previewed,
  executing,
  success,
  kernelUnavailable,
  unsupportedOperation,
  invalid,
  failed,
  suppressed,
  rolledBack,
}

class TransitionParameters {
  TransitionParameters({
    this.sweepType,
    this.loftType,
    this.thickness = 0,
    this.merge = false,
    this.closed = false,
    this.strategy = 'smooth',
  });
  SweepType? sweepType;
  LoftType? loftType;
  double thickness;
  bool merge, closed;
  String strategy;
  Map<String, dynamic> toJson() => {
    'sweepType': sweepType?.name,
    'loftType': loftType?.name,
    'thickness': thickness,
    'merge': merge,
    'closed': closed,
    'strategy': strategy,
  };
}

class TransitionInput {
  TransitionInput({
    required this.profileIds,
    this.sectionIds = const [],
    this.pathIds = const [],
    this.guideIds = const [],
    this.referenceIds = const [],
    this.kernelProfiles = const [],
    this.kernelPaths = const [],
    this.kernelGuides = const [],
  });
  final List<String> profileIds, sectionIds, pathIds, guideIds, referenceIds;
  final List<ShapeHandle> kernelProfiles, kernelPaths, kernelGuides;
  Map<String, dynamic> toJson() => {
    'profileIds': profileIds,
    'sectionIds': sectionIds,
    'pathIds': pathIds,
    'guideIds': guideIds,
    'referenceIds': referenceIds,
    'kernelProfiles': kernelProfiles.map((e) => e.toJson()).toList(),
    'kernelPaths': kernelPaths.map((e) => e.toJson()).toList(),
    'kernelGuides': kernelGuides.map((e) => e.toJson()).toList(),
  };
}

class TransitionFeature {
  TransitionFeature({
    required this.family,
    required this.input,
    required this.parameters,
    String? id,
  }) : id = id ?? 'transition:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id;
  final TransitionFamily family;
  final TransitionInput input;
  final TransitionParameters parameters;
  final DateTime timestamp;
  int version = 1;
  TransitionStatus status = TransitionStatus.prepared;
  ShapeHandle? output;
  final List<String> dependencies = [], diagnostics = [];
  Map<String, dynamic> toJson() => {
    'id': id,
    'family': family.name,
    'input': input.toJson(),
    'parameters': parameters.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'status': status.name,
    'output': output?.toJson(),
    'dependencies': dependencies,
    'diagnostics': diagnostics,
  };
}

class TransitionExecutionResult {
  const TransitionExecutionResult(
    this.status, {
    this.shape,
    this.diagnostics = const [],
  });
  final TransitionStatus status;
  final ShapeHandle? shape;
  final List<String> diagnostics;
  bool get success => status == TransitionStatus.success && shape != null;
}
