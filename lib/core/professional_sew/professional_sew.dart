import '../feature_lifecycle/feature_update_solver.dart';
import '../parametric_solver/parametric_solver.dart';

enum SewSelectionMode { individual, window, group, reconstructionManager }

enum SewRelationState { preview, sewed, partiallyUnsewed, unsewed }

class SewGapAnalysis {
  const SewGapAnalysis({
    required this.minimum,
    required this.maximum,
    required this.average,
    required this.coincidentEdges,
    required this.incompatibleRegions,
  });

  final double minimum, maximum, average;
  final int coincidentEdges, incompatibleRegions;
  bool within(double tolerance) => maximum <= tolerance;

  Map<String, dynamic> toJson() => {
    'minimum': minimum,
    'maximum': maximum,
    'average': average,
    'coincidentEdges': coincidentEdges,
    'incompatibleRegions': incompatibleRegions,
  };

  factory SewGapAnalysis.fromJson(Map<String, dynamic> json) => SewGapAnalysis(
    minimum: (json['minimum'] as num?)?.toDouble() ?? 0,
    maximum: (json['maximum'] as num?)?.toDouble() ?? 0,
    average: (json['average'] as num?)?.toDouble() ?? 0,
    coincidentEdges: json['coincidentEdges'] as int? ?? 0,
    incompatibleRegions: json['incompatibleRegions'] as int? ?? 0,
  );
}

class ProfessionalSewContract {
  const ProfessionalSewContract({
    required this.surfaceEntityIds,
    this.selectionMode = SewSelectionMode.individual,
    this.tolerance = .05,
    this.compensate = false,
    this.gaps = const SewGapAnalysis(
      minimum: 0,
      maximum: 0,
      average: 0,
      coincidentEdges: 0,
      incompatibleRegions: 0,
    ),
    this.state = SewRelationState.preview,
    this.detachedSurfaceIds = const [],
  });

  final List<String> surfaceEntityIds, detachedSurfaceIds;
  final SewSelectionMode selectionMode;
  final double tolerance;
  final bool compensate;
  final SewGapAnalysis gaps;
  final SewRelationState state;

  List<String> get attachedSurfaceIds => surfaceEntityIds
      .where((id) => !detachedSurfaceIds.contains(id))
      .toList(growable: false);

  bool get closed =>
      state == SewRelationState.sewed &&
      gaps.incompatibleRegions == 0 &&
      gaps.within(tolerance);

  void validate() {
    if (surfaceEntityIds.toSet().length < 2) {
      throw ArgumentError('Sew requires two or more independent Surfaces.');
    }
    if (!tolerance.isFinite || tolerance <= 0) {
      throw ArgumentError('Sew tolerance must be greater than zero.');
    }
    if (!surfaceEntityIds.toSet().containsAll(detachedSurfaceIds)) {
      throw ArgumentError(
        'Partial Unsew can detach only Body member Surfaces.',
      );
    }
    if (compensate == false && gaps.maximum > tolerance) {
      throw StateError(
        'Gap ${gaps.maximum.toStringAsFixed(3)} mm is outside Sew tolerance.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'surfaceEntityIds': surfaceEntityIds,
    'selectionMode': selectionMode.name,
    'tolerance': tolerance,
    'compensate': compensate,
    'gaps': gaps.toJson(),
    'state': state.name,
    'detachedSurfaceIds': detachedSurfaceIds,
    'surfacesPreserved': true,
    'createsSolid': false,
  };

  factory ProfessionalSewContract.fromJson(Map<String, dynamic> json) =>
      ProfessionalSewContract(
        surfaceEntityIds: (json['surfaceEntityIds'] as List).cast<String>(),
        selectionMode: SewSelectionMode.values.byName(
          json['selectionMode'] as String? ?? 'individual',
        ),
        tolerance: (json['tolerance'] as num?)?.toDouble() ?? .05,
        compensate: json['compensate'] as bool? ?? false,
        gaps: SewGapAnalysis.fromJson(
          Map<String, dynamic>.from(json['gaps'] as Map? ?? const {}),
        ),
        state: SewRelationState.values.byName(
          json['state'] as String? ?? 'preview',
        ),
        detachedSurfaceIds: (json['detachedSurfaceIds'] as List? ?? const [])
            .cast<String>(),
      );
}

abstract final class ProfessionalSewNaming {
  static String nextId(Iterable<String> ids) {
    final used = ids.toSet();
    var index = 1;
    while (used.contains('Body${index.toString().padLeft(3, '0')}')) {
      index++;
    }
    return 'Body${index.toString().padLeft(3, '0')}';
  }
}

class ProfessionalSewConstraintAdapter {
  const ProfessionalSewConstraintAdapter({
    this.featureUpdates = const FeatureUpdateSolver(),
  });
  final FeatureUpdateSolver featureUpdates;

  ParametricMotionPlan solve(ProfessionalSewContract contract) {
    contract.validate();
    final attached = contract.attachedSurfaceIds;
    return featureUpdates.update(
      request: ParametricSolveRequest(
        first: attached.first,
        second: attached.last,
        degreesOfFreedom: [
          for (final id in attached) ParametricDegreeOfFreedom(id),
          const ParametricDegreeOfFreedom('sew.tolerance'),
        ],
        restrictions: [
          ParametricRestriction('sew.members', {...attached}),
        ],
        priorities: [
          ParametricPriority(attached.first, 0),
          const ParametricPriority('sew.tolerance', 1),
        ],
        preferredAnchor: attached.first,
      ),
      apply: (plan) => plan,
    );
  }
}
