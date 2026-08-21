import '../feature_lifecycle/feature_update_solver.dart';
import '../parametric_solver/parametric_solver.dart';

enum SweepInputKind { sketch, referenceCurve, edge }

class SweepInputReference {
  const SweepInputReference({
    required this.entityId,
    required this.kind,
    required this.revision,
    required this.shapeId,
  });

  final String entityId;
  final SweepInputKind kind;
  final int revision;
  final String shapeId;

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'kind': kind.name,
    'revision': revision,
    'shapeId': shapeId,
  };

  factory SweepInputReference.fromJson(Map<String, dynamic> json) =>
      SweepInputReference(
        entityId: json['entityId'] as String,
        kind: SweepInputKind.values.byName(json['kind'] as String),
        revision: (json['revision'] as num).toInt(),
        shapeId: json['shapeId'] as String,
      );
}

class SweepHealth {
  const SweepHealth({
    required this.valid,
    required this.pathOk,
    required this.profileOk,
    required this.continuity,
    required this.ready,
    required this.message,
  });

  final bool valid, pathOk, profileOk, continuity, ready;
  final String message;

  Map<String, dynamic> toJson() => {
    'valid': valid,
    'pathOk': pathOk,
    'profileOk': profileOk,
    'continuity': continuity,
    'ready': ready,
    'message': message,
  };
}

/// Converts platform inputs to the entity-neutral Solver contract. Semantic
/// knowledge about Sketches, Reference Curves and Edges remains here.
class SweepConstraintAdapter {
  const SweepConstraintAdapter({
    this.featureUpdates = const FeatureUpdateSolver(),
  });

  final FeatureUpdateSolver featureUpdates;

  ParametricMotionPlan solve({
    required SweepInputReference profile,
    required SweepInputReference path,
  }) {
    _validate(profile, path);
    return featureUpdates.update(
      request: ParametricSolveRequest(
        first: profile.entityId,
        second: path.entityId,
        degreesOfFreedom: [
          ParametricDegreeOfFreedom(profile.entityId),
          ParametricDegreeOfFreedom(path.entityId),
        ],
        restrictions: [
          ParametricRestriction('sweep.profile', {profile.entityId}),
          ParametricRestriction('sweep.path', {path.entityId}),
        ],
        priorities: [
          ParametricPriority(profile.entityId, 0),
          ParametricPriority(path.entityId, 1),
        ],
        preferredAnchor: profile.entityId,
      ),
      apply: (plan) => plan,
    );
  }

  SweepHealth health({
    required SweepInputReference profile,
    required SweepInputReference path,
  }) {
    try {
      solve(profile: profile, path: path);
      final profileOk = profile.shapeId.isNotEmpty;
      final pathOk = path.shapeId.isNotEmpty;
      final ready = profileOk && pathOk;
      return SweepHealth(
        valid: ready,
        pathOk: pathOk,
        profileOk: profileOk,
        continuity: ready,
        ready: ready,
        message: ready
            ? 'Sweep is ready.'
            : 'Profile or path geometry is unavailable.',
      );
    } on Object catch (error) {
      return SweepHealth(
        valid: false,
        pathOk: false,
        profileOk: false,
        continuity: false,
        ready: false,
        message: error.toString(),
      );
    }
  }

  void _validate(SweepInputReference profile, SweepInputReference path) {
    if (profile.entityId == path.entityId) {
      throw ArgumentError('Sweep requires distinct profile and path inputs.');
    }
    final valid = switch ((profile.kind, path.kind)) {
      (SweepInputKind.sketch, SweepInputKind.sketch) => true,
      (SweepInputKind.sketch, SweepInputKind.referenceCurve) => true,
      (SweepInputKind.edge, SweepInputKind.edge) => true,
      _ => false,
    };
    if (!valid) {
      throw ArgumentError(
        'Use Sketch + Sketch Path, Sketch + Reference Curve, or Edge + Edge.',
      );
    }
  }
}

abstract final class ProfessionalSweepNaming {
  static String nextId(Iterable<String> existingIds) {
    final used = existingIds.toSet();
    var sequence = 1;
    while (used.contains('Sweep${sequence.toString().padLeft(3, '0')}')) {
      sequence++;
    }
    return 'Sweep${sequence.toString().padLeft(3, '0')}';
  }
}
