import '../feature_lifecycle/feature_update_solver.dart';
import '../parametric_solver/parametric_solver.dart';

enum SurfaceFilletSelectionMode {
  edge,
  multipleEdge,
  loop,
  face,
  faceToFace,
  tangentChain,
}

enum SurfaceFilletSizeMode { constantRadius, variableRadius, constantWidth }

enum SurfaceFilletContinuity { g0, g1, g2Prepared }

enum SurfaceFilletOverflow { smoothPrepared, cliffPrepared }

class SurfaceFilletRadiusPoint {
  const SurfaceFilletRadiusPoint(this.parameter, this.value);
  final double parameter, value;
  Map<String, dynamic> toJson() => {'parameter': parameter, 'value': value};
  factory SurfaceFilletRadiusPoint.fromJson(Map<String, dynamic> json) =>
      SurfaceFilletRadiusPoint(
        (json['parameter'] as num).toDouble(),
        (json['value'] as num).toDouble(),
      );
}

class ProfessionalSurfaceFilletContract {
  const ProfessionalSurfaceFilletContract({
    required this.sourceEntityIds,
    required this.edgeEntityIds,
    required this.selectionMode,
    required this.sizeMode,
    this.radius = 5,
    this.width = 5,
    this.radiusPoints = const [],
    this.trim = true,
    this.extend = false,
    this.compensate = false,
    this.compensationGap = 0,
    this.continuity = SurfaceFilletContinuity.g1,
    this.overflow = SurfaceFilletOverflow.smoothPrepared,
  });

  final List<String> sourceEntityIds, edgeEntityIds;
  final SurfaceFilletSelectionMode selectionMode;
  final SurfaceFilletSizeMode sizeMode;
  final double radius, width, compensationGap;
  final List<SurfaceFilletRadiusPoint> radiusPoints;
  final bool trim, extend, compensate;
  final SurfaceFilletContinuity continuity;
  final SurfaceFilletOverflow overflow;

  void validate() {
    if (sourceEntityIds.isEmpty) {
      throw ArgumentError('Surface Fillet requires support geometry.');
    }
    if (selectionMode == SurfaceFilletSelectionMode.faceToFace) {
      if (sourceEntityIds.length != 2) {
        throw ArgumentError('Face to Face requires exactly two Surfaces.');
      }
    } else if (selectionMode != SurfaceFilletSelectionMode.face &&
        edgeEntityIds.isEmpty) {
      throw ArgumentError('Select at least one Edge for Surface Fillet.');
    }
    if (continuity == SurfaceFilletContinuity.g2Prepared) {
      throw UnsupportedError('Surface Fillet G2 is prepared only.');
    }
    final value = sizeMode == SurfaceFilletSizeMode.constantWidth
        ? width
        : radius;
    if (!value.isFinite || value <= 0) {
      throw ArgumentError('Fillet size must be greater than zero.');
    }
    if (sizeMode == SurfaceFilletSizeMode.variableRadius) {
      if (radiusPoints.length < 2 ||
          radiusPoints.any(
            (item) =>
                item.parameter < 0 ||
                item.parameter > 1 ||
                item.value <= 0 ||
                !item.value.isFinite,
          )) {
        throw ArgumentError(
          'Variable Radius requires two or more valid points.',
        );
      }
    }
    if (compensate && (!compensationGap.isFinite || compensationGap < 0)) {
      throw ArgumentError('Compensation gap is invalid.');
    }
  }

  Map<String, dynamic> toJson() => {
    'sourceEntityIds': sourceEntityIds,
    'edgeEntityIds': edgeEntityIds,
    'selectionMode': selectionMode.name,
    'sizeMode': sizeMode.name,
    'radius': radius,
    'width': width,
    'radiusPoints': radiusPoints.map((item) => item.toJson()).toList(),
    'trim': trim,
    'extend': extend,
    'compensate': compensate,
    'compensationGap': compensationGap,
    'continuity': continuity.name,
    'overflow': overflow.name,
    'g2Supported': false,
  };

  factory ProfessionalSurfaceFilletContract.fromJson(
    Map<String, dynamic> json,
  ) => ProfessionalSurfaceFilletContract(
    sourceEntityIds: (json['sourceEntityIds'] as List).cast<String>(),
    edgeEntityIds: (json['edgeEntityIds'] as List? ?? const []).cast<String>(),
    selectionMode: SurfaceFilletSelectionMode.values.byName(
      json['selectionMode'] as String? ?? 'edge',
    ),
    sizeMode: SurfaceFilletSizeMode.values.byName(
      json['sizeMode'] as String? ?? 'constantRadius',
    ),
    radius: (json['radius'] as num?)?.toDouble() ?? 5,
    width: (json['width'] as num?)?.toDouble() ?? 5,
    radiusPoints: (json['radiusPoints'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => SurfaceFilletRadiusPoint.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(),
    trim: json['trim'] as bool? ?? true,
    extend: json['extend'] as bool? ?? false,
    compensate: json['compensate'] as bool? ?? false,
    compensationGap: (json['compensationGap'] as num?)?.toDouble() ?? 0,
    continuity: SurfaceFilletContinuity.values.byName(
      json['continuity'] as String? ?? 'g1',
    ),
    overflow: SurfaceFilletOverflow.values.byName(
      json['overflow'] as String? ?? 'smoothPrepared',
    ),
  );
}

abstract final class ProfessionalSurfaceFilletNaming {
  static String nextId(Iterable<String> ids) {
    final used = ids.toSet();
    var index = 1;
    while (used.contains('Fillet${index.toString().padLeft(3, '0')}')) {
      index++;
    }
    return 'Fillet${index.toString().padLeft(3, '0')}';
  }
}

class ProfessionalSurfaceFilletConstraintAdapter {
  const ProfessionalSurfaceFilletConstraintAdapter({
    this.featureUpdates = const FeatureUpdateSolver(),
  });
  final FeatureUpdateSolver featureUpdates;

  ParametricMotionPlan solve(ProfessionalSurfaceFilletContract contract) {
    contract.validate();
    final first = contract.sourceEntityIds.first;
    final second = contract.edgeEntityIds.isEmpty
        ? contract.sourceEntityIds.last
        : contract.edgeEntityIds.first;
    return featureUpdates.update(
      request: ParametricSolveRequest(
        first: first,
        second: second,
        degreesOfFreedom: [
          ParametricDegreeOfFreedom(first),
          ParametricDegreeOfFreedom(second),
          const ParametricDegreeOfFreedom('surfaceFillet.size'),
        ],
        restrictions: [
          ParametricRestriction('surfaceFillet.supports', {
            ...contract.sourceEntityIds,
          }),
          ParametricRestriction('surfaceFillet.boundaries', {
            ...contract.edgeEntityIds,
          }),
        ],
        priorities: [
          ParametricPriority(first, 0),
          const ParametricPriority('surfaceFillet.size', 1),
        ],
        preferredAnchor: first,
      ),
      apply: (plan) => plan,
    );
  }
}
