import 'dart:math' as math;

import '../../smart_regions/models/geometry.dart';
import '../constraints/sketch_constraint.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch_context.dart';

enum ConstraintState {
  satisfied,
  violated,
  redundant,
  unsupported,
  conflicting,
}

class ConstraintDiagnostic {
  const ConstraintDiagnostic(
    this.constraintId,
    this.state,
    this.error,
    this.explanation, {
    this.suggestion,
  });
  final String constraintId;
  final ConstraintState state;
  final double error;
  final String explanation;
  final String? suggestion;
}

class SketchSolveResult {
  const SketchSolveResult({
    required this.entities,
    required this.diagnostics,
    required this.remainingDegreesOfFreedom,
    required this.converged,
  });
  final List<SketchEntity> entities;
  final List<ConstraintDiagnostic> diagnostics;
  final int remainingDegreesOfFreedom;
  final bool converged;
  bool get overConstrained =>
      diagnostics.any((value) => value.state == ConstraintState.conflicting);
}

abstract interface class SketchConstraintRule {
  SketchConstraintType get type;
  int get removedDegreesOfFreedom;
  ConstraintDiagnostic evaluate(
    SketchConstraint constraint,
    Map<String, SketchEntity> entities,
    double tolerance,
  );
  Map<String, SketchEntity> apply(
    SketchConstraint constraint,
    Map<String, SketchEntity> entities,
  );
}

class AdaptiveConstraintSolver {
  AdaptiveConstraintSolver({
    List<SketchConstraintRule> rules = const [],
    this.tolerance = 1e-6,
  }) {
    for (final rule in [..._coreRules, ...rules]) {
      _rules[rule.type] = rule;
    }
  }
  final double tolerance;
  final Map<SketchConstraintType, SketchConstraintRule> _rules = {};
  static const List<SketchConstraintRule> _coreRules = [
    CoincidentRule(),
    HorizontalRule(),
    VerticalRule(),
    ParallelRule(),
    PerpendicularRule(),
    DistanceRule(),
  ];

  SketchSolveResult solve(
    List<SketchEntity> source,
    List<SketchConstraint> constraints,
  ) {
    var entities = {for (final entity in source) entity.id: entity};
    final diagnostics = <ConstraintDiagnostic>[],
        signatures = <String>{},
        exclusive = <String, Map<String, double>>{};
    var removed = 0;
    for (final constraint
        in constraints.where((value) => value.enabled).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority))) {
      final signature =
          '${constraint.type.name}:${[...constraint.entityIds]..sort()}:${constraint.parameters}';
      if (!signatures.add(signature)) {
        diagnostics.add(
          ConstraintDiagnostic(
            constraint.id,
            ConstraintState.redundant,
            0,
            'Equivalent constraint already exists',
            suggestion: 'Remove this constraint',
          ),
        );
        continue;
      }
      if ({
        SketchConstraintType.distance,
        SketchConstraintType.angle,
        SketchConstraintType.radius,
        SketchConstraintType.diameter,
      }.contains(constraint.type)) {
        final key =
                '${constraint.type.name}:${[...constraint.entityIds]..sort()}',
            previous = exclusive[key];
        if (previous != null &&
            previous.toString() != constraint.parameters.toString()) {
          diagnostics.add(
            ConstraintDiagnostic(
              constraint.id,
              ConstraintState.conflicting,
              double.infinity,
              'Incompatible dimensional constraints target the same entities',
              suggestion: 'Keep one dimensional value or lower its priority',
            ),
          );
          continue;
        }
        exclusive[key] = constraint.parameters;
      }
      final rule = _rules[constraint.type];
      if (rule == null) {
        diagnostics.add(
          ConstraintDiagnostic(
            constraint.id,
            ConstraintState.unsupported,
            double.infinity,
            'Constraint requires a geometry adapter',
          ),
        );
        continue;
      }
      final initial = rule.evaluate(constraint, entities, tolerance);
      if (initial.state == ConstraintState.violated) {
        entities = rule.apply(constraint, entities);
      }
      final result = rule.evaluate(constraint, entities, tolerance);
      diagnostics.add(result);
      if (result.state == ConstraintState.satisfied) {
        removed += rule.removedDegreesOfFreedom;
      }
    }
    final total = source.fold<int>(
      0,
      (value, entity) => value + entity.anchors.length * 3,
    );
    return SketchSolveResult(
      entities: entities.values.toList(),
      diagnostics: diagnostics,
      remainingDegreesOfFreedom: math.max(0, total - removed),
      converged: diagnostics.every(
        (value) => {
          ConstraintState.satisfied,
          ConstraintState.redundant,
        }.contains(value.state),
      ),
    );
  }
}

abstract class _TwoPointRule implements SketchConstraintRule {
  const _TwoPointRule();
  SketchEntity entity(
    SketchConstraint c,
    Map<String, SketchEntity> values,
    int index,
  ) =>
      values[c.entityIds[index]] ??
      (throw StateError('Missing entity ${c.entityIds[index]}'));
  Vec3 direction(SketchEntity value) =>
      (value.anchors.last.position - value.anchors.first.position).normalized;
  SketchEntity replaceLast(SketchEntity value, Vec3 position) => value.copyWith(
    anchors: [
      ...value.anchors.take(value.anchors.length - 1),
      SketchAnchor(position: position, contextId: value.anchors.last.contextId),
    ],
  );
}

class CoincidentRule extends _TwoPointRule {
  const CoincidentRule();
  @override
  SketchConstraintType get type => SketchConstraintType.coincident;
  @override
  int get removedDegreesOfFreedom => 3;
  @override
  ConstraintDiagnostic evaluate(
    SketchConstraint c,
    Map<String, SketchEntity> e,
    double t,
  ) {
    final error =
        (entity(c, e, 0).anchors.last.position -
                entity(c, e, 1).anchors.first.position)
            .length;
    return ConstraintDiagnostic(
      c.id,
      error <= t ? ConstraintState.satisfied : ConstraintState.violated,
      error,
      error <= t ? 'Endpoints are coincident' : 'Endpoints are separated',
      suggestion: 'Move the first endpoint onto the second',
    );
  }

  @override
  Map<String, SketchEntity> apply(
    SketchConstraint c,
    Map<String, SketchEntity> e,
  ) => {
    ...e,
    c.entityIds[0]: replaceLast(
      entity(c, e, 0),
      entity(c, e, 1).anchors.first.position,
    ),
  };
}

class HorizontalRule extends _TwoPointRule {
  const HorizontalRule();
  @override
  SketchConstraintType get type => SketchConstraintType.horizontal;
  @override
  int get removedDegreesOfFreedom => 1;
  @override
  ConstraintDiagnostic evaluate(
    SketchConstraint c,
    Map<String, SketchEntity> e,
    double t,
  ) {
    final value = entity(c, e, 0);
    final error =
        (value.anchors.last.position.y - value.anchors.first.position.y).abs();
    return ConstraintDiagnostic(
      c.id,
      error <= t ? ConstraintState.satisfied : ConstraintState.violated,
      error,
      'Horizontal alignment',
    );
  }

  @override
  Map<String, SketchEntity> apply(
    SketchConstraint c,
    Map<String, SketchEntity> e,
  ) {
    final value = entity(c, e, 0),
        p = value.anchors.last.position,
        start = value.anchors.first.position;
    return {...e, value.id: replaceLast(value, Vec3(p.x, start.y, p.z))};
  }
}

class VerticalRule extends _TwoPointRule {
  const VerticalRule();
  @override
  SketchConstraintType get type => SketchConstraintType.vertical;
  @override
  int get removedDegreesOfFreedom => 1;
  @override
  ConstraintDiagnostic evaluate(
    SketchConstraint c,
    Map<String, SketchEntity> e,
    double t,
  ) {
    final value = entity(c, e, 0);
    final error =
        (value.anchors.last.position.x - value.anchors.first.position.x).abs();
    return ConstraintDiagnostic(
      c.id,
      error <= t ? ConstraintState.satisfied : ConstraintState.violated,
      error,
      'Vertical alignment',
    );
  }

  @override
  Map<String, SketchEntity> apply(
    SketchConstraint c,
    Map<String, SketchEntity> e,
  ) {
    final value = entity(c, e, 0),
        p = value.anchors.last.position,
        start = value.anchors.first.position;
    return {...e, value.id: replaceLast(value, Vec3(start.x, p.y, p.z))};
  }
}

class ParallelRule extends _TwoPointRule {
  const ParallelRule();
  @override
  SketchConstraintType get type => SketchConstraintType.parallel;
  @override
  int get removedDegreesOfFreedom => 2;
  @override
  ConstraintDiagnostic evaluate(
    SketchConstraint c,
    Map<String, SketchEntity> e,
    double t,
  ) {
    final error = direction(
      entity(c, e, 0),
    ).cross(direction(entity(c, e, 1))).length;
    return ConstraintDiagnostic(
      c.id,
      error <= t ? ConstraintState.satisfied : ConstraintState.violated,
      error,
      'Parallel directions',
    );
  }

  @override
  Map<String, SketchEntity> apply(
    SketchConstraint c,
    Map<String, SketchEntity> e,
  ) {
    final value = entity(c, e, 0),
        start = value.anchors.first.position,
        d = direction(entity(c, e, 1)),
        length = (value.anchors.last.position - start).length;
    return {
      ...e,
      value.id: replaceLast(
        value,
        start + Vec3(d.x * length, d.y * length, d.z * length),
      ),
    };
  }
}

class PerpendicularRule extends _TwoPointRule {
  const PerpendicularRule();
  @override
  SketchConstraintType get type => SketchConstraintType.perpendicular;
  @override
  int get removedDegreesOfFreedom => 1;
  @override
  ConstraintDiagnostic evaluate(
    SketchConstraint c,
    Map<String, SketchEntity> e,
    double t,
  ) {
    final error = direction(
      entity(c, e, 0),
    ).dot(direction(entity(c, e, 1))).abs();
    return ConstraintDiagnostic(
      c.id,
      error <= t ? ConstraintState.satisfied : ConstraintState.violated,
      error,
      'Perpendicular directions',
    );
  }

  @override
  Map<String, SketchEntity> apply(
    SketchConstraint c,
    Map<String, SketchEntity> e,
  ) {
    final value = entity(c, e, 0),
        start = value.anchors.first.position,
        d = direction(entity(c, e, 1)),
        helper = d.z.abs() < .9 ? const Vec3(0, 0, 1) : const Vec3(0, 1, 0),
        normal = d.cross(helper).normalized,
        length = (value.anchors.last.position - start).length;
    return {
      ...e,
      value.id: replaceLast(
        value,
        start + Vec3(normal.x * length, normal.y * length, normal.z * length),
      ),
    };
  }
}

class DistanceRule extends _TwoPointRule {
  const DistanceRule();
  @override
  SketchConstraintType get type => SketchConstraintType.distance;
  @override
  int get removedDegreesOfFreedom => 1;
  @override
  ConstraintDiagnostic evaluate(
    SketchConstraint c,
    Map<String, SketchEntity> e,
    double t,
  ) {
    final value = entity(c, e, 0),
        target = c.parameters['distance'] ?? 0,
        error =
            ((value.anchors.last.position - value.anchors.first.position)
                        .length -
                    target)
                .abs();
    return ConstraintDiagnostic(
      c.id,
      error <= t ? ConstraintState.satisfied : ConstraintState.violated,
      error,
      'Fixed distance',
    );
  }

  @override
  Map<String, SketchEntity> apply(
    SketchConstraint c,
    Map<String, SketchEntity> e,
  ) {
    final value = entity(c, e, 0),
        start = value.anchors.first.position,
        d = direction(value),
        target = c.parameters['distance'] ?? 0;
    return {
      ...e,
      value.id: replaceLast(
        value,
        start + Vec3(d.x * target, d.y * target, d.z * target),
      ),
    };
  }
}
