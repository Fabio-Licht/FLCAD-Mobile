import 'dart:math' as math;

import '../../sketch_engine/entities/sketch_entities.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../diagnostics/constraint_diagnostics.dart';
import '../graph/constraint_graph.dart';
import '../models/constraint_models.dart';

class IncrementalConstraintSolver {
  final Set<String> _dirty = {};
  Set<String> get dirty => Set.unmodifiable(_dirty);
  void markDirty(String id, ConstraintGraph dependencies) {
    _dirty
      ..add(id)
      ..addAll(dependencies.downstream(id));
  }

  void clear() => _dirty.clear();

  Future<ConstraintSolveResult> solve({
    required Map<String, SketchConstraint> constraints,
    required Map<String, SketchEntity> entities,
    required ConstraintGraphSet graphs,
    Iterable<String>? only,
  }) async {
    final watch = Stopwatch()..start();
    final requested = only?.toSet();
    final queue =
        constraints.values
            .where(
              (c) =>
                  requested == null ||
                  requested.contains(c.id) ||
                  _dirty.contains(c.id),
            )
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
    final diagnostics = <ConstraintDiagnostic>[];
    final solved = <String>{};
    final signatures = <String, String>{};
    final drivingValues = <String, SketchConstraint>{};
    final directional = <String, SketchConstraintType>{};
    var iterations = 0;
    for (final constraint in queue) {
      iterations++;
      constraint.diagnostics.clear();
      if (!constraint.enabled || constraint.suppressed) continue;
      final missing = constraint.references
          .where((id) => !entities.containsKey(_entityId(id)))
          .toList();
      if (missing.isNotEmpty) {
        constraint.status = ConstraintStatus.invalid;
        final d = ConstraintDiagnostic(
          ConstraintDiagnosticKind.missingReference,
          'Missing references: ${missing.join(', ')}',
          constraintIds: [constraint.id],
          suggestedFix: 'Restore or replace the referenced entity',
        );
        diagnostics.add(d);
        constraint.diagnostics.add(d.message);
        continue;
      }
      final duplicate = signatures[constraint.signature];
      if (duplicate != null) {
        constraint.status = ConstraintStatus.conflicting;
        diagnostics.add(
          ConstraintDiagnostic(
            ConstraintDiagnosticKind.duplicate,
            'Duplicate constraint',
            constraintIds: [duplicate, constraint.id],
            suggestedFix: 'Delete the duplicate constraint',
          ),
        );
        continue;
      }
      signatures[constraint.signature] = constraint.id;
      if (constraint.value != null) {
        final key =
            '${constraint.type.name}:${constraint.references.join('|')}';
        final prior = drivingValues[key];
        if (prior != null && prior.value != constraint.value) {
          constraint.status = ConstraintStatus.conflicting;
          final d = ConstraintDiagnostic(
            ConstraintDiagnosticKind.conflict,
            'Conflicting driving values ${prior.value} and ${constraint.value}',
            constraintIds: [prior.id, constraint.id],
            suggestedFix:
                'Suppress or change the lower-priority driving constraint',
          );
          diagnostics.add(d);
          constraint.diagnostics.add(d.message);
          continue;
        }
        drivingValues[key] = constraint;
      }
      if ((constraint.type == SketchConstraintType.horizontal ||
              constraint.type == SketchConstraintType.vertical) &&
          constraint.references.isNotEmpty) {
        final prior = directional[constraint.references.first];
        if (prior != null && prior != constraint.type) {
          constraint.status = ConstraintStatus.overdefined;
          diagnostics.add(
            ConstraintDiagnostic(
              ConstraintDiagnosticKind.overConstraint,
              'Horizontal and vertical constraints overdefine the same entity',
              constraintIds: [constraint.id],
              suggestedFix: 'Suppress one directional constraint',
            ),
          );
          continue;
        }
        directional[constraint.references.first] = constraint.type;
      }
      _apply(constraint, entities);
      constraint.status = constraint.driven
          ? ConstraintStatus.driven
          : constraint.driving
          ? ConstraintStatus.driving
          : ConstraintStatus.satisfied;
      solved.add(constraint.id);
    }
    final active = constraints.values
        .where((c) => c.enabled && !c.suppressed)
        .length;
    if (active < entities.length) {
      diagnostics.add(
        const ConstraintDiagnostic(
          ConstraintDiagnosticKind.underConstraint,
          'Sketch retains degrees of freedom',
          suggestedFix: 'Add driving constraints or fix geometry',
        ),
      );
      for (final c in constraints.values.where(
        (c) => c.status == ConstraintStatus.unsatisfied,
      )) {
        c.status = ConstraintStatus.underdefined;
      }
    }
    _dirty.removeAll(queue.map((e) => e.id));
    watch.stop();
    return ConstraintSolveResult(
      statistics: SolverStatistics(
        executionTime: watch.elapsed,
        iterations: iterations,
        solved: solved.length,
        failed: queue.length - solved.length,
        failureReason: diagnostics
            .where((d) => d.kind == ConstraintDiagnosticKind.conflict)
            .firstOrNull
            ?.message,
      ),
      diagnostics: diagnostics,
      solvedIds: solved,
    );
  }

  void _apply(SketchConstraint c, Map<String, SketchEntity> entities) {
    if (c.references.isEmpty) return;
    final first = entities[_entityId(c.references.first)]!;
    if (first is SketchLine &&
        (c.type == SketchConstraintType.horizontal ||
            c.type == SketchConstraintType.vertical)) {
      final start = (first.parameters['start'] as List).cast<num>();
      final end = (first.parameters['end'] as List).cast<num>();
      first.parameters['end'] = c.type == SketchConstraintType.horizontal
          ? [end[0].toDouble(), start[1].toDouble(), end[2].toDouble()]
          : [start[0].toDouble(), end[1].toDouble(), end[2].toDouble()];
      first.version++;
      first.refreshDerivedParameters();
    }
    if (c.type == SketchConstraintType.coincident && c.references.length > 1) {
      final target = _point(c.references[0], entities);
      if (target != null) _setPoint(c.references[1], target, entities);
    }
    if ((c.type == SketchConstraintType.parallel ||
            c.type == SketchConstraintType.perpendicular) &&
        c.references.length > 1) {
      final a = entities[_entityId(c.references[0])];
      final b = entities[_entityId(c.references[1])];
      if (a is SketchLine && b is SketchLine) {
        final a0 = SketchVector.fromJson(a.parameters['start']);
        final a1 = SketchVector.fromJson(a.parameters['end']);
        final b0 = SketchVector.fromJson(b.parameters['start']);
        final b1 = SketchVector.fromJson(b.parameters['end']);
        final delta = b1 - b0;
        final length = math.sqrt(
          delta.x * delta.x + delta.y * delta.y + delta.z * delta.z,
        );
        final angle =
            math.atan2(a1.y - a0.y, a1.x - a0.x) +
            (c.type == SketchConstraintType.perpendicular ? math.pi / 2 : 0);
        b.parameters['end'] = SketchVector(
          b0.x + length * math.cos(angle),
          b0.y + length * math.sin(angle),
          b0.z,
        ).toJson();
        b.version++;
        b.refreshDerivedParameters();
      }
    }
    if (c.type == SketchConstraintType.concentric && c.references.length > 1) {
      final a = entities[_entityId(c.references[0])];
      final b = entities[_entityId(c.references[1])];
      if ((a is SketchCircle || a is SketchArc) &&
          (b is SketchCircle || b is SketchArc)) {
        b!.parameters['center'] = List<double>.from(
          (a!.parameters['center'] as List).cast<num>().map(
            (e) => e.toDouble(),
          ),
        );
        b.version++;
      }
    }
  }

  static String _entityId(String reference) {
    final marker = reference.lastIndexOf(':');
    if (marker <= 0) return reference;
    final suffix = reference.substring(marker + 1);
    return suffix == 'start' || suffix == 'end' || suffix == 'point'
        ? reference.substring(0, marker)
        : reference;
  }

  static SketchVector? _point(
    String reference,
    Map<String, SketchEntity> entities,
  ) {
    final entity = entities[_entityId(reference)];
    if (entity is SketchPoint) {
      return SketchVector.fromJson(entity.parameters['point']);
    }
    if (entity is SketchLine) {
      final endpoint = reference.endsWith(':start') ? 'start' : 'end';
      return SketchVector.fromJson(entity.parameters[endpoint]);
    }
    return null;
  }

  static void _setPoint(
    String reference,
    SketchVector point,
    Map<String, SketchEntity> entities,
  ) {
    final entity = entities[_entityId(reference)];
    if (entity is SketchPoint) {
      entity.parameters['point'] = point.toJson();
    } else if (entity is SketchLine) {
      entity.parameters[reference.endsWith(':start') ? 'start' : 'end'] = point
          .toJson();
      entity.refreshDerivedParameters();
    } else {
      return;
    }
    entity!.version++;
  }
}
