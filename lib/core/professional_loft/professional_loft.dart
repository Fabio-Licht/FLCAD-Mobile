import '../feature_lifecycle/feature_update_solver.dart';
import '../parametric_solver/parametric_solver.dart';

enum LoftSectionKind { sketch, referenceCurve, edge }

class LoftSectionReference {
  const LoftSectionReference({
    required this.entityId,
    required this.kind,
    required this.revision,
    required this.shapeId,
  });

  final String entityId;
  final LoftSectionKind kind;
  final int revision;
  final String shapeId;

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'kind': kind.name,
    'revision': revision,
    'shapeId': shapeId,
  };

  factory LoftSectionReference.fromJson(Map<String, dynamic> json) =>
      LoftSectionReference(
        entityId: json['entityId'] as String,
        kind: LoftSectionKind.values.byName(json['kind'] as String),
        revision: (json['revision'] as num).toInt(),
        shapeId: json['shapeId'] as String,
      );
}

class LoftHealth {
  const LoftHealth({
    required this.valid,
    required this.topologyOk,
    required this.boundariesOk,
    required this.ready,
    this.message = 'Loft is ready.',
  });

  final bool valid;
  final bool topologyOk;
  final bool boundariesOk;
  final bool ready;
  final String message;

  Map<String, dynamic> toJson() => {
    'valid': valid,
    'topologyOk': topologyOk,
    'boundariesOk': boundariesOk,
    'ready': ready,
    'message': message,
  };
}

/// Translates Loft sources to the entity-neutral Geometry Constraint Solver
/// contract. No Sketch, Curve, Edge, or kernel type reaches the Solver.
class LoftConstraintAdapter {
  const LoftConstraintAdapter({
    this.featureUpdates = const FeatureUpdateSolver(),
  });

  final FeatureUpdateSolver featureUpdates;

  ParametricMotionPlan solve(List<LoftSectionReference> sections) {
    if (sections.length != 2) {
      throw ArgumentError('Professional Loft requires exactly two sections.');
    }
    if (sections.first.entityId == sections.last.entityId) {
      throw ArgumentError('Professional Loft requires two distinct sections.');
    }
    if (sections.first.kind != sections.last.kind) {
      throw ArgumentError(
        'Select two Sketches, two Reference Curves, or two Edges.',
      );
    }
    final ids = sections.map((item) => item.entityId).toList(growable: false);
    return featureUpdates.update(
      request: ParametricSolveRequest(
        first: ids.first,
        second: ids.last,
        degreesOfFreedom: [for (final id in ids) ParametricDegreeOfFreedom(id)],
        dependencies: [ParametricDependency('loft.sections', ids.toSet())],
        priorities: [
          ParametricPriority(ids.first, 0),
          ParametricPriority(ids.last, 1),
        ],
        preferredAnchor: ids.first,
      ),
      apply: (plan) => plan,
    );
  }

  LoftHealth health(List<LoftSectionReference> sections) {
    try {
      solve(sections);
      final shapesOk = sections.every((item) => item.shapeId.isNotEmpty);
      return LoftHealth(
        valid: shapesOk,
        topologyOk: shapesOk,
        boundariesOk: shapesOk,
        ready: shapesOk,
        message: shapesOk
            ? 'Loft is ready.'
            : 'One or more section boundaries are unavailable.',
      );
    } on Object catch (error) {
      return LoftHealth(
        valid: false,
        topologyOk: false,
        boundariesOk: false,
        ready: false,
        message: error.toString(),
      );
    }
  }
}

abstract final class ProfessionalLoftNaming {
  static String nextId(Iterable<String> existingIds) {
    final used = existingIds.toSet();
    var sequence = 1;
    while (used.contains('Loft${sequence.toString().padLeft(3, '0')}')) {
      sequence++;
    }
    return 'Loft${sequence.toString().padLeft(3, '0')}';
  }
}
