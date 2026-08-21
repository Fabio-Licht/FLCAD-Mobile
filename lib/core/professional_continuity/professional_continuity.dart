import '../feature_lifecycle/feature_update_solver.dart';
import '../parametric_solver/parametric_solver.dart';

enum ProfessionalContinuityLevel { disconnected, g0, g1, g2Prepared }

enum ProfessionalAnalysisKind { zebra, reflection, curvature }

class ContinuitySurfaceReference {
  const ContinuitySurfaceReference({
    required this.id,
    required this.shapeId,
    required this.boundaryIds,
    required this.revision,
  });

  final String id;
  final String shapeId;
  final Set<String> boundaryIds;
  final int revision;
}

class SurfaceAnalysisSetting {
  const SurfaceAnalysisSetting({
    required this.kind,
    required this.enabled,
    required this.intensity,
  });

  final ProfessionalAnalysisKind kind;
  final bool enabled;
  final double intensity;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'enabled': enabled,
    'intensity': intensity.clamp(0.0, 1.0),
  };

  factory SurfaceAnalysisSetting.fromJson(Map<String, dynamic> json) =>
      SurfaceAnalysisSetting(
        kind: ProfessionalAnalysisKind.values.byName(json['kind'] as String),
        enabled: json['enabled'] as bool? ?? false,
        intensity: (json['intensity'] as num? ?? 0.7).toDouble(),
      );
}

class SurfaceContinuityRelation {
  const SurfaceContinuityRelation({
    required this.id,
    required this.firstSurfaceId,
    required this.secondSurfaceId,
    required this.level,
    required this.sharedBoundaryIds,
    required this.quality,
    required this.confirmed,
    required this.revision,
    required this.updatedAt,
  });

  final String id;
  final String firstSurfaceId;
  final String secondSurfaceId;
  final ProfessionalContinuityLevel level;
  final List<String> sharedBoundaryIds;
  final double quality;
  final bool confirmed;
  final int revision;
  final DateTime updatedAt;

  bool get g0 => level == ProfessionalContinuityLevel.g0 || g1;
  bool get g1 => level == ProfessionalContinuityLevel.g1;

  Map<String, dynamic> toJson() => {
    'schema': 'flcad.surface-continuity',
    'version': 1,
    'id': id,
    'firstSurfaceId': firstSurfaceId,
    'secondSurfaceId': secondSurfaceId,
    'level': level.name,
    'sharedBoundaryIds': sharedBoundaryIds,
    'quality': quality.clamp(0.0, 1.0),
    'confirmed': confirmed,
    'revision': revision,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'solverContract': 'flcad.geometry-constraint-solver/v1',
    'g2Supported': false,
  };

  factory SurfaceContinuityRelation.fromJson(Map<String, dynamic> json) =>
      SurfaceContinuityRelation(
        id: json['id'] as String,
        firstSurfaceId: json['firstSurfaceId'] as String,
        secondSurfaceId: json['secondSurfaceId'] as String,
        level: ProfessionalContinuityLevel.values.byName(
          json['level'] as String,
        ),
        sharedBoundaryIds: (json['sharedBoundaryIds'] as List? ?? const [])
            .cast<String>(),
        quality: (json['quality'] as num? ?? 0).toDouble(),
        confirmed: json['confirmed'] as bool? ?? false,
        revision: (json['revision'] as num? ?? 1).toInt(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// Entity-neutral quality engine. Entity adapters provide only persistent
/// references, boundaries and degrees of freedom.
class ProfessionalContinuityEngine {
  const ProfessionalContinuityEngine({
    this.featureUpdates = const FeatureUpdateSolver(),
  });

  final FeatureUpdateSolver featureUpdates;

  SurfaceContinuityRelation inspectG0(
    ContinuitySurfaceReference first,
    ContinuitySurfaceReference second,
  ) {
    _validate(first, second);
    final shared = first.boundaryIds.intersection(second.boundaryIds).toList()
      ..sort();
    return SurfaceContinuityRelation(
      id: relationId(first.id, second.id),
      firstSurfaceId: first.id,
      secondSurfaceId: second.id,
      level: shared.isEmpty
          ? ProfessionalContinuityLevel.disconnected
          : ProfessionalContinuityLevel.g0,
      sharedBoundaryIds: shared,
      quality: shared.isEmpty ? 0 : 1,
      confirmed: true,
      revision: 1,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  SurfaceContinuityRelation previewG1(
    ContinuitySurfaceReference first,
    ContinuitySurfaceReference second,
  ) {
    final g0 = inspectG0(first, second);
    if (!g0.g0) {
      throw StateError('G1 requires surfaces with a shared boundary.');
    }
    featureUpdates.update(
      request: ParametricSolveRequest(
        first: first.id,
        second: second.id,
        degreesOfFreedom: [
          ParametricDegreeOfFreedom(first.id, fixed: true),
          ParametricDegreeOfFreedom(second.id),
        ],
        restrictions: [
          ParametricRestriction('continuity.boundary', {first.id, second.id}),
        ],
        anchors: {first.id},
        preferredAnchor: first.id,
      ),
      apply: (plan) => plan,
    );
    return SurfaceContinuityRelation(
      id: g0.id,
      firstSurfaceId: first.id,
      secondSurfaceId: second.id,
      level: ProfessionalContinuityLevel.g1,
      sharedBoundaryIds: g0.sharedBoundaryIds,
      quality: 1,
      confirmed: false,
      revision: g0.revision,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  SurfaceContinuityRelation confirmG1(
    SurfaceContinuityRelation preview, {
    int? previousRevision,
  }) {
    if (preview.level != ProfessionalContinuityLevel.g1 || preview.confirmed) {
      throw StateError('A pending G1 preview is required.');
    }
    return SurfaceContinuityRelation(
      id: preview.id,
      firstSurfaceId: preview.firstSurfaceId,
      secondSurfaceId: preview.secondSurfaceId,
      level: ProfessionalContinuityLevel.g1,
      sharedBoundaryIds: preview.sharedBoundaryIds,
      quality: preview.quality,
      confirmed: true,
      revision: (previousRevision ?? preview.revision) + 1,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  static String relationId(String first, String second) {
    final ids = [first, second]..sort();
    return 'Continuity:${ids.first}:${ids.last}';
  }

  void _validate(
    ContinuitySurfaceReference first,
    ContinuitySurfaceReference second,
  ) {
    if (first.id == second.id ||
        first.shapeId.isEmpty ||
        second.shapeId.isEmpty) {
      throw ArgumentError('Two distinct persistent surfaces are required.');
    }
  }
}
