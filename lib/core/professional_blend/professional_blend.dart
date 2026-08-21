import '../feature_lifecycle/feature_update_solver.dart';
import '../parametric_solver/parametric_solver.dart';

enum BlendContinuity { g0, g1, g2Prepared }

class BlendSurfaceReference {
  const BlendSurfaceReference({
    required this.entityId,
    required this.revision,
    required this.shapeId,
    this.boundaryEntityId,
    this.boundaryShapeId,
    this.continuity = BlendContinuity.g0,
    this.influence = 1,
  });

  final String entityId;
  final int revision;
  final String shapeId;
  final String? boundaryEntityId, boundaryShapeId;
  final BlendContinuity continuity;
  final double influence;

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'revision': revision,
    'shapeId': shapeId,
    'boundaryEntityId': boundaryEntityId,
    'boundaryShapeId': boundaryShapeId,
    'continuity': continuity.name,
    'influence': influence,
  };

  factory BlendSurfaceReference.fromJson(Map<String, dynamic> json) =>
      BlendSurfaceReference(
        entityId: json['entityId'] as String,
        revision: (json['revision'] as num).toInt(),
        shapeId: json['shapeId'] as String,
        boundaryEntityId: json['boundaryEntityId'] as String?,
        boundaryShapeId: json['boundaryShapeId'] as String?,
        continuity: BlendContinuity.values.byName(
          json['continuity'] as String? ?? 'g0',
        ),
        influence: (json['influence'] as num?)?.toDouble() ?? 1,
      );
}

class BlendHealth {
  const BlendHealth({
    required this.valid,
    required this.boundaries,
    required this.continuity,
    required this.ready,
    required this.quality,
    required this.message,
  });

  final bool valid, boundaries, continuity, ready;
  final double quality;
  final String message;

  Map<String, dynamic> toJson() => {
    'valid': valid,
    'boundaries': boundaries,
    'continuity': continuity,
    'ready': ready,
    'quality': quality.clamp(0.0, 1.0),
    'message': message,
  };
}

/// Blend-specific adapter for the entity-neutral Geometry Constraint Solver.
/// The Solver sees only freedoms, restrictions, anchors and priorities.
class BlendConstraintAdapter {
  const BlendConstraintAdapter({
    this.featureUpdates = const FeatureUpdateSolver(),
  });

  final FeatureUpdateSolver featureUpdates;

  ParametricMotionPlan solve({
    required BlendSurfaceReference first,
    required BlendSurfaceReference second,
    required BlendContinuity continuity,
  }) {
    _validate(first, second, continuity);
    return featureUpdates.update(
      request: ParametricSolveRequest(
        first: first.entityId,
        second: second.entityId,
        degreesOfFreedom: [
          ParametricDegreeOfFreedom(first.entityId),
          ParametricDegreeOfFreedom(second.entityId),
        ],
        restrictions: [
          ParametricRestriction('blend.first', {first.entityId}),
          ParametricRestriction('blend.second', {second.entityId}),
        ],
        priorities: [
          ParametricPriority(first.entityId, 0),
          ParametricPriority(second.entityId, 1),
        ],
        preferredAnchor: first.entityId,
      ),
      apply: (plan) => plan,
    );
  }

  BlendHealth health({
    required BlendSurfaceReference first,
    required BlendSurfaceReference second,
    required BlendContinuity continuity,
  }) {
    try {
      solve(first: first, second: second, continuity: continuity);
      final surfacesOk = first.shapeId.isNotEmpty && second.shapeId.isNotEmpty;
      final firstHasBoundary = first.boundaryEntityId != null;
      final secondHasBoundary = second.boundaryEntityId != null;
      final boundaryPair = firstHasBoundary == secondHasBoundary;
      final boundariesOk =
          boundaryPair &&
          (!firstHasBoundary ||
              (first.boundaryShapeId?.isNotEmpty == true &&
                  second.boundaryShapeId?.isNotEmpty == true));
      final ready = surfacesOk && boundariesOk;
      return BlendHealth(
        valid: ready,
        boundaries: boundariesOk,
        continuity: continuity != BlendContinuity.g2Prepared,
        ready: ready,
        quality: ready
            ? ([first, second]
                          .where(
                            (item) => item.continuity == BlendContinuity.g1,
                          )
                          .length /
                      2 *
                      .2 +
                  .8)
            : 0,
        message: ready
            ? 'Blend is ready.'
            : 'Select no boundaries or one boundary for each Surface.',
      );
    } on Object catch (error) {
      return BlendHealth(
        valid: false,
        boundaries: false,
        continuity: false,
        ready: false,
        quality: 0,
        message: error.toString(),
      );
    }
  }

  void _validate(
    BlendSurfaceReference first,
    BlendSurfaceReference second,
    BlendContinuity continuity,
  ) {
    if (first.entityId == second.entityId ||
        first.shapeId.isEmpty ||
        second.shapeId.isEmpty) {
      throw ArgumentError('Blend requires two distinct persistent Surfaces.');
    }
    if (continuity == BlendContinuity.g2Prepared) {
      throw UnsupportedError('G2 is prepared but not implemented.');
    }
    for (final side in [first, second]) {
      if (side.continuity == BlendContinuity.g2Prepared) {
        throw UnsupportedError('G2 is prepared but not implemented.');
      }
      if (!side.influence.isFinite ||
          side.influence <= 0 ||
          side.influence > 1) {
        throw ArgumentError(
          'Blend side influence must be greater than 0 and at most 1.',
        );
      }
      if (side.continuity == BlendContinuity.g1 &&
          side.boundaryEntityId == null) {
        throw ArgumentError(
          'G1 requires one explicit boundary on its support Surface.',
        );
      }
    }
    if (first.boundaryEntityId == null || second.boundaryEntityId == null) {
      throw ArgumentError(
        'Select one boundary for each participating Surface.',
      );
    }
  }
}

abstract final class ProfessionalBlendNaming {
  static String nextId(Iterable<String> existingIds) {
    final used = existingIds.toSet();
    var sequence = 1;
    while (used.contains('Blend${sequence.toString().padLeft(3, '0')}')) {
      sequence++;
    }
    return 'Blend${sequence.toString().padLeft(3, '0')}';
  }
}
