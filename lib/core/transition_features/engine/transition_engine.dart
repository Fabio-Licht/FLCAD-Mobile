import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../feature_modeling/models/feature_models.dart' as platform;
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../advisor/transition_advisor.dart';
import '../analytics/transition_analytics.dart';
import '../graph/transition_graph.dart';
import '../history/transition_history.dart';
import '../integration/transition_kernel_adapter.dart';
import '../models/transition_models.dart';
import '../preview/transition_preview.dart';
import '../repository/transition_repository.dart';
import '../runtime/transition_runtime.dart';
import '../validation/transition_quality.dart';
import '../validation/transition_validation.dart';

class TransitionEngine {
  TransitionEngine({
    required this.projectId,
    required this.kernel,
    required this.profiles,
    required this.platformApi,
    required this.repository,
    TransitionRuntime? runtime,
    TransitionAnalytics? analytics,
    TransitionHistory? history,
  }) : runtime = runtime ?? TransitionRuntime(),
       analytics = analytics ?? TransitionAnalytics(),
       history = history ?? TransitionHistory();
  final String projectId;
  final GeometryKernelAPI kernel;
  final ProfileRecognitionApi profiles;
  final FeatureModelingApi platformApi;
  final TransitionRepository repository;
  final TransitionRuntime runtime;
  final TransitionAnalytics analytics;
  final TransitionHistory history;
  final graph = TransitionGraph();
  final Map<String, TransitionFeature> features = {};
  final Map<String, TransitionPreview> previews = {};
  final _undo = <_Change>[], _redo = <_Change>[];
  final validator = const TransitionValidator();
  TransitionFeature prepare(
    TransitionFamily family,
    TransitionInput input,
    TransitionParameters parameters,
  ) {
    final feature = TransitionFeature(
          family: family,
          input: input,
          parameters: parameters,
        ),
        definition = platform.FeatureDefinition(
          type: family == TransitionFamily.sweep
              ? platform.FeatureType.sweep
              : platform.FeatureType.loft,
          name: 'Professional ${family.name}',
          requiredInputs: family == TransitionFamily.sweep
              ? const ['profile', 'path']
              : const ['sections'],
          supported: true,
        ),
        platformFeature = platform.FeatureInstance(
          id: feature.id,
          definition: definition,
          inputs: [
            for (final id in input.profileIds)
              platform.FeatureInput(
                'profile',
                platform.FeatureReference(id, kind: 'profile'),
              ),
            for (final id in input.pathIds)
              platform.FeatureInput(
                'path',
                platform.FeatureReference(id, kind: 'path'),
              ),
            for (final id in input.guideIds)
              platform.FeatureInput(
                'guide',
                platform.FeatureReference(id, kind: 'guide'),
              ),
          ],
          parameters: parameters.toJson(),
        );
    features[feature.id] = feature;
    graph.add(feature.id);
    platformApi.engine.add(platformFeature);
    if (family == TransitionFamily.sweep) {
      analytics.sweeps++;
    } else {
      analytics.lofts++;
    }
    history.record(TransitionHistoryAction.create, feature.id);
    _record(
      _Change(
        () => _remove(feature.id),
        () => _restore(feature, platformFeature),
      ),
    );
    return feature;
  }

  void _remove(String id) {
    features.remove(id);
    previews.remove(id);
    platformApi.engine.delete(id);
  }

  void _restore(TransitionFeature f, platform.FeatureInstance p) {
    features[f.id] = f;
    graph.add(f.id);
    platformApi.engine.add(p);
  }

  TransitionPreview preview(String id) {
    final f = features[id] ?? (throw StateError('Unknown transition: $id')),
        value = const TransitionPreviewEngine().create(f, kernel.descriptor);
    previews[id] = value;
    f.status = TransitionStatus.previewed;
    analytics.totalComplexity += value.complexityScore;
    history.record(TransitionHistoryAction.preview, id);
    return value;
  }

  TransitionValidationResult validate(String id, {bool kernelHealthy = true}) =>
      validator.validate(
        features[id] ?? (throw StateError('Unknown transition: $id')),
        profiles.profiles,
        kernel.descriptor,
        kernelHealthy: kernelHealthy,
      );
  Future<TransitionExecutionResult> confirm(String id) async {
    final f = features[id] ?? (throw StateError('Unknown transition: $id')),
        health = await kernel.healthCheck(),
        validation = validate(
          id,
          kernelHealthy: health.status != KernelHealthStatus.unavailable,
        ),
        blocking = validation.issues
            .where(
              (e) =>
                  e.type != TransitionIssueType.kernelUnavailable &&
                  e.type != TransitionIssueType.unsupportedCapability,
            )
            .toList();
    if (blocking.isNotEmpty) {
      f.status = TransitionStatus.invalid;
      f.diagnostics
        ..clear()
        ..addAll(blocking.map((e) => e.message));
      analytics.failures++;
      return TransitionExecutionResult(
        TransitionStatus.invalid,
        diagnostics: f.diagnostics,
      );
    }
    f.status = TransitionStatus.executing;
    final result = await TransitionFeatureKernelAdapter(
          kernel,
        ).execute(projectId, f),
        p = platformApi.engine.features[id]!;
    f.status = result.status;
    f.output = result.shape;
    f.diagnostics
      ..clear()
      ..addAll(result.diagnostics);
    final state = switch (result.status) {
      TransitionStatus.success => platform.FeatureExecutionState.ready,
      TransitionStatus.kernelUnavailable =>
        platform.FeatureExecutionState.kernelUnavailable,
      TransitionStatus.unsupportedOperation =>
        platform.FeatureExecutionState.unsupported,
      _ => platform.FeatureExecutionState.failed,
    };
    p.state = state;
    p.result = platform.FeatureResult(
      success: result.success,
      state: state,
      diagnostics: result.diagnostics,
      outputs: [
        if (result.shape != null)
          platform.FeatureOutput('shape', handle: result.shape),
      ],
    );
    analytics.rebuilds++;
    if (result.success) {
      analytics.successes++;
      analytics.kernelAvailable++;
    } else {
      analytics.failures++;
    }
    history.record(
      result.success
          ? TransitionHistoryAction.confirm
          : TransitionHistoryAction.failure,
      id,
    );
    return result;
  }

  Future<TransitionExecutionResult> rebuild(String id) async {
    final watch = Stopwatch()..start(), result = await confirm(id);
    watch.stop();
    analytics.totalRebuildMicros += watch.elapsedMicroseconds;
    history.record(TransitionHistoryAction.rebuild, id);
    return result;
  }

  void updateParameters(String id, void Function(TransitionParameters) change) {
    final f = features[id] ?? (throw StateError('Unknown transition: $id'));
    change(f.parameters);
    f.version++;
    f.status = TransitionStatus.prepared;
    platformApi.engine.markDirty(id);
    analytics.parameterUpdates++;
    history.record(TransitionHistoryAction.edit, id);
  }

  void addDependency(String id, String parent) {
    final f = features[id] ?? (throw StateError('Unknown transition: $id'));
    graph.connect(parent, id);
    if (!f.dependencies.contains(parent)) f.dependencies.add(parent);
    final p = platformApi.engine.features[id]!,
        graphs = platformApi.engine.graphs;
    if (!p.dependencies.contains(parent)) p.dependencies.add(parent);
    graphs.dependencies.connect(parent, id);
    graphs.execution.connect(parent, id);
    graphs.parents.connect(parent, id);
    graphs.children.connect(parent, id);
    graphs.impact.connect(parent, id);
    platformApi.engine.markDirty(id);
    analytics.dependencyUpdates++;
  }

  void rollback(String id) {
    final f = features[id] ?? (throw StateError('Unknown transition: $id'));
    f.output = null;
    f.status = TransitionStatus.rolledBack;
    analytics.rollbacks++;
    history.record(TransitionHistoryAction.rollback, id);
  }

  void suppress(String id, bool value) {
    final f = features[id] ?? (throw StateError('Unknown transition: $id'));
    f.status = value ? TransitionStatus.suppressed : TransitionStatus.prepared;
    platformApi.engine.suppress(id, value);
    history.record(
      value
          ? TransitionHistoryAction.suppress
          : TransitionHistoryAction.unsuppress,
      id,
    );
  }

  TransitionQuality quality(String id) =>
      const TransitionQualityEngine().evaluate(
        features[id] ?? (throw StateError('Unknown transition: $id')),
        validate(id),
      );
  List<TransitionRecommendation> recommendations(String id) =>
      const TransitionAdvisor().analyze(
        features[id] ?? (throw StateError('Unknown transition: $id')),
        validate(id),
      );
  bool undo() {
    if (_undo.isEmpty) return false;
    final c = _undo.removeLast();
    c.undo();
    _redo.add(c);
    analytics.undo++;
    history.record(TransitionHistoryAction.undo, 'transition');
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    final c = _redo.removeLast();
    c.redo();
    _undo.add(c);
    analytics.redo++;
    history.record(TransitionHistoryAction.redo, 'transition');
    return true;
  }

  void _record(_Change change) {
    _undo.add(change);
    _redo.clear();
  }

  Future<void> persist() => repository.save(
    features: features.values,
    history: history,
    analytics: analytics,
    previews: previews.values,
  );
}

class _Change {
  const _Change(this.undo, this.redo);
  final void Function() undo, redo;
}
