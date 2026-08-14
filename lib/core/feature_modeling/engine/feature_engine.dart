import '../analytics/feature_analytics.dart';
import '../dependencies/dependency_engine.dart';
import '../graph/feature_graph.dart';
import '../history/feature_history.dart';
import '../models/feature_models.dart';
import '../parameters/feature_parameters.dart';
import '../repository/feature_repository.dart';
import '../runtime/feature_runtime.dart';
import '../timeline/feature_timeline.dart';
import '../validation/feature_validation.dart';

abstract interface class FeatureExecutor {
  Future<FeatureResult> execute(
    FeatureInstance feature,
    FeatureContext context,
  );
}

class UnavailableFeatureExecutor implements FeatureExecutor {
  const UnavailableFeatureExecutor();
  @override
  Future<FeatureResult> execute(FeatureInstance f, FeatureContext c) async =>
      FeatureResult(
        success: false,
        state: f.definition.supported
            ? FeatureExecutionState.kernelUnavailable
            : FeatureExecutionState.unsupported,
        diagnostics: [
          f.definition.supported
              ? 'Geometry kernel unavailable'
              : 'Unsupported feature contract: ${f.definition.type.name}',
        ],
      );
}

class FeatureModelingEngine {
  FeatureModelingEngine({
    required this.projectId,
    required this.repository,
    FeatureExecutor? executor,
    FeatureModelingRuntime? runtime,
    FeatureAnalytics? analytics,
    FeatureHistory? history,
  }) : executor = executor ?? const UnavailableFeatureExecutor(),
       runtime = runtime ?? FeatureModelingRuntime(),
       analytics = analytics ?? FeatureAnalytics(),
       history = history ?? FeatureHistory();
  final String projectId;
  final FeatureRepository repository;
  final FeatureExecutor executor;
  final FeatureModelingRuntime runtime;
  final FeatureAnalytics analytics;
  final FeatureHistory history;
  final graphs = FeatureGraphSet();
  final timeline = FeatureTimeline();
  final parameters = FeatureParameterSet();
  final dependencyEngine = const FeatureDependencyEngine();
  final Map<String, FeatureInstance> features = {};
  final List<_FeatureChange> _undo = [], _redo = [];
  FeatureValidationResult validation = const FeatureValidationResult([]);
  FeatureInstance add(FeatureInstance feature) {
    if (features.containsKey(feature.id)) {
      throw StateError('Duplicate feature id: ${feature.id}');
    }
    _addInternal(feature);
    _record(
      _FeatureChange(
        () => _removeInternal(feature.id),
        () => _addInternal(feature),
      ),
    );
    history.record(FeatureHistoryAction.create, feature.id);
    return feature;
  }

  void _addInternal(FeatureInstance f) {
    features[f.id] = f;
    timeline.add(f.id);
    dependencyEngine.register(f, features, graphs);
    timeline.markDirty([f.id, ...graphs.dependencies.downstream(f.id)]);
    analytics.featureCount = features.length;
    analytics.dependencies = graphs.dependencies.edges.values.fold(
      0,
      (a, b) => a + b.length,
    );
  }

  FeatureInstance _removeInternal(String id) {
    final f = features.remove(id) ?? (throw StateError('Unknown feature: $id'));
    timeline.remove(id);
    for (final g in graphs.all) {
      g.remove(id);
    }
    analytics.featureCount = features.length;
    return f;
  }

  void delete(String id) {
    final f = features[id] ?? (throw StateError('Unknown feature: $id'));
    _removeInternal(id);
    _record(_FeatureChange(() => _addInternal(f), () => _removeInternal(id)));
    history.record(FeatureHistoryAction.delete, id);
  }

  void suppress(String id, bool value) {
    final f = features[id] ?? (throw StateError('Unknown feature: $id')),
        before = f.suppressed;
    void apply(bool v) {
      f.suppressed = v;
      f.state = v
          ? FeatureExecutionState.suppressed
          : FeatureExecutionState.edited;
      timeline.markDirty([id, ...graphs.dependencies.downstream(id)]);
      analytics.suppressedFeatures = features.values
          .where((x) => x.suppressed)
          .length;
    }

    apply(value);
    _record(_FeatureChange(() => apply(before), () => apply(value)));
    history.record(
      value ? FeatureHistoryAction.suppress : FeatureHistoryAction.unsuppress,
      id,
    );
  }

  void freeze(String id, bool value) {
    final f = features[id] ?? (throw StateError('Unknown feature: $id')),
        before = f.frozen;
    void apply(bool v) {
      f.frozen = v;
      f.state = v ? FeatureExecutionState.frozen : FeatureExecutionState.edited;
    }

    apply(value);
    _record(_FeatureChange(() => apply(before), () => apply(value)));
    history.record(
      value ? FeatureHistoryAction.freeze : FeatureHistoryAction.unfreeze,
      id,
    );
  }

  void markDirty(String id) {
    if (!features.containsKey(id)) throw StateError('Unknown feature: $id');
    timeline.markDirty([id, ...graphs.dependencies.downstream(id)]);
  }

  FeatureValidationResult validate() {
    final issues = <FeatureValidationIssue>[
      ...dependencyEngine.validate(features, graphs).issues,
    ];
    for (final f in features.values) {
      for (final required in f.definition.requiredInputs) {
        if (!f.inputs.any((i) => i.name == required)) {
          issues.add(
            FeatureValidationIssue(
              FeatureValidationIssueType.missingInput,
              'Missing input: $required',
              featureId: f.id,
            ),
          );
        }
      }
      for (final input in f.inputs.where(
        (i) => i.reference.kind == 'feature',
      )) {
        if (!features.containsKey(input.reference.id)) {
          issues.add(
            FeatureValidationIssue(
              FeatureValidationIssueType.invalidReference,
              'Invalid reference: ${input.reference.id}',
              featureId: f.id,
            ),
          );
        }
      }
      if (!f.definition.supported) {
        issues.add(
          FeatureValidationIssue(
            FeatureValidationIssueType.unsupportedFeature,
            'Feature contract is not implemented: ${f.definition.type.name}',
            featureId: f.id,
          ),
        );
      }
    }
    for (final issue in parameters.validate()) {
      issues.add(
        FeatureValidationIssue(
          FeatureValidationIssueType.invalidParameter,
          issue,
        ),
      );
    }
    validation = FeatureValidationResult(issues);
    return validation;
  }

  Future<List<FeatureResult>> rebuild({
    Iterable<String>? only,
    bool includeDownstream = true,
  }) async {
    final watch = Stopwatch()..start(),
        requested = only?.toSet() ?? Set<String>.of(timeline.rebuildQueue);
    if (includeDownstream) {
      for (final id in List.of(requested)) {
        requested.addAll(graphs.dependencies.downstream(id));
      }
    }
    final order = timeline.executionOrder(requested),
        before = {
          for (final id in order)
            id: (features[id]!.state, features[id]!.result),
        };
    final results = <FeatureResult>[];
    try {
      validate();
      for (final id in order) {
        final f = features[id]!;
        if (f.suppressed || f.frozen) continue;
        f.state = FeatureExecutionState.rebuilding;
        final result = await executor.execute(
          f,
          FeatureContext(projectId: projectId, featureId: id),
        );
        f.result = result;
        f.state = result.state;
        f.diagnostics
          ..clear()
          ..addAll(result.diagnostics);
        results.add(result);
        if (!result.success) analytics.failures++;
      }
      timeline.rebuildQueue.removeAll(order);
      history.record(FeatureHistoryAction.rebuild, order.join(','));
      return results;
    } catch (_) {
      for (final e in before.entries) {
        features[e.key]!.state = e.value.$1;
        features[e.key]!.result = e.value.$2;
      }
      analytics.rollbackCount++;
      history.record(FeatureHistoryAction.rollback, 'rebuild');
      rethrow;
    } finally {
      watch.stop();
      analytics.rebuildCount++;
      analytics.totalRebuildMicros += watch.elapsedMicroseconds;
    }
  }

  Future<List<FeatureResult>> rebuildAll() => rebuild(only: features.keys);
  Future<List<FeatureResult>> rebuildPartial(Iterable<String> ids) =>
      rebuild(only: ids, includeDownstream: false);
  Future<List<FeatureResult>> rebuildIncremental() => rebuild();
  void rollbackModel(String featureId) {
    if (!features.containsKey(featureId)) {
      throw StateError('Unknown feature: $featureId');
    }
    timeline.rollbackAt(featureId);
    final position = timeline.entries
        .firstWhere((e) => e.featureId == featureId)
        .position;
    for (final e in timeline.entries.where((e) => e.position > position)) {
      features[e.featureId]!.state = FeatureExecutionState.pending;
      timeline.markDirty([e.featureId]);
    }
    analytics.rollbackCount++;
    history.record(FeatureHistoryAction.rollback, featureId);
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    final c = _undo.removeLast();
    c.undo();
    _redo.add(c);
    history.record(FeatureHistoryAction.undo, 'feature');
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    final c = _redo.removeLast();
    c.redo();
    _undo.add(c);
    history.record(FeatureHistoryAction.redo, 'feature');
    return true;
  }

  void _record(_FeatureChange c) {
    _undo.add(c);
    _redo.clear();
  }

  Future<void> persist() => repository.save(
    features: features.values,
    history: history,
    graphs: graphs,
    timeline: timeline,
    parameters: parameters,
    analytics: analytics,
  );
}

class _FeatureChange {
  const _FeatureChange(this.undo, this.redo);
  final void Function() undo, redo;
}
