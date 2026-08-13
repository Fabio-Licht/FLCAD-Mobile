import '../../smart_regions/models/geometry.dart';
import '../models/adaptive_surface.dart';
import '../models/surface_geometry.dart';

class SurfaceBuildRequest {
  const SurfaceBuildRequest({
    required this.projectId,
    required this.sourceIds,
    required this.samples,
    required this.intent,
    this.parameters = const {},
    this.targetKind,
  });
  final String projectId;
  final List<String> sourceIds;
  final List<Vec3> samples;
  final String intent;
  final Map<String, dynamic> parameters;
  final SurfaceKind? targetKind;
  String get fingerprint =>
      '${sourceIds.join(':')}:${samples.map((p) => p.toJson()).join()}:$parameters';
}

class SurfaceCandidate {
  const SurfaceCandidate({
    required this.solverId,
    required this.geometry,
    required this.metrics,
    required this.complexity,
    this.metadata = const {},
  });
  final String solverId;
  final SurfaceGeometry geometry;
  final SurfaceMetrics metrics;
  final double complexity;
  final Map<String, dynamic> metadata;
}

abstract interface class SurfaceBuilder {
  String get id;
  Set<SurfaceKind> get supportedKinds;
  Future<SurfaceCandidate> build(SurfaceBuildRequest request);
}
