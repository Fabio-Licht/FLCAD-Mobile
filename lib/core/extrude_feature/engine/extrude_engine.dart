import 'dart:math' as math;
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../feature_modeling/models/feature_models.dart' as platform;
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../advisor/extrude_advisor.dart';
import '../analytics/extrude_analytics.dart';
import '../graph/extrude_graph.dart';
import '../history/extrude_history.dart';
import '../integration/feature_kernel_adapter.dart';
import '../models/extrude_models.dart';
import '../preview/extrude_preview.dart';
import '../repository/extrude_repository.dart';
import '../runtime/extrude_runtime.dart';
import '../validation/extrude_quality.dart';
import '../validation/extrude_validation.dart';

class ExtrudeEngine {
  ExtrudeEngine({
    required this.projectId,
    required this.kernel,
    required this.profiles,
    required this.platformApi,
    required this.repository,
    ExtrudeRuntime? runtime,
    ExtrudeAnalytics? analytics,
    ExtrudeHistory? history,
  }) : runtime = runtime ?? ExtrudeRuntime(),
       analytics = analytics ?? ExtrudeAnalytics(),
       history = history ?? ExtrudeHistory();
  final String projectId;
  final GeometryKernelAPI kernel;
  final ProfileRecognitionApi profiles;
  final FeatureModelingApi platformApi;
  final ExtrudeRepository repository;
  final ExtrudeRuntime runtime;
  final ExtrudeAnalytics analytics;
  final ExtrudeHistory history;
  final graph = ExtrudeGraph();
  final Map<String, ExtrudeFeature> extrudes = {};
  final Map<String, ExtrudePreview> previews = {};
  final List<_ExtrudeChange> _undo = [], _redo = [];
  final validator = const ExtrudeValidator();
  ExtrudeFeature prepare(ExtrudeInput input, ExtrudeParameters parameters) {
    final e = ExtrudeFeature(input: input, parameters: parameters),
        feature = platform.FeatureInstance(
          id: e.id,
          definition: const platform.FeatureDefinition(
            type: platform.FeatureType.extrude,
            name: 'Professional Extrude',
            requiredInputs: ['profile'],
            supported: true,
          ),
          inputs: [
            platform.FeatureInput(
              'profile',
              platform.FeatureReference(
                input.kernelProfile?.persistentId ??
                    input.profileIds.firstOrNull ??
                    'missing',
                kind: input.kernelProfile == null ? 'profile' : 'shape',
              ),
            ),
          ],
          parameters: parameters.toJson(),
        );
    e.platformFeatureId = feature.id;
    extrudes[e.id] = e;
    graph.add(e.id);
    platformApi.engine.add(feature);
    analytics
      ..extrudes = extrudes.length
      ..totalDistance += parameters.distance;
    history.record(ExtrudeHistoryAction.create, e.id);
    _record(_ExtrudeChange(() => _remove(e.id), () => _restore(e, feature)));
    return e;
  }

  void _remove(String id) {
    extrudes.remove(id);
    previews.remove(id);
    platformApi.engine.delete(id);
  }

  void _restore(ExtrudeFeature e, platform.FeatureInstance f) {
    extrudes[e.id] = e;
    graph.add(e.id);
    platformApi.engine.add(f);
  }

  ExtrudePreview preview(String id) {
    final e = extrudes[id] ?? (throw StateError('Unknown extrude: $id')),
        selected = profiles.profiles
            .where((p) => e.input.profileIds.contains(p.id))
            .toList(),
        area = selected.fold<double>(0, (s, p) => s + p.area),
        size = math.sqrt(area.abs());
    final value = ExtrudePreviewEngine().create(
      e,
      profileArea: area,
      profileWidth: size,
      profileHeight: size,
      kernel: kernel.descriptor,
    );
    previews[id] = value;
    e.status = ExtrudeStatus.previewed;
    history.record(ExtrudeHistoryAction.preview, id);
    return value;
  }

  Future<ExtrudeExecutionResult> confirm(String id) async {
    final e = extrudes[id] ?? (throw StateError('Unknown extrude: $id')),
        health = await kernel.healthCheck(),
        validation = validator.validate(
          e,
          profiles.profiles,
          kernel.descriptor,
          kernelHealthy: health.status != KernelHealthStatus.unavailable,
        );
    final blocking = validation.issues
        .where(
          (i) =>
              i.type !=
                  ExtrudeValidationIssueType.unsupportedKernelCapability &&
              i.type != ExtrudeValidationIssueType.kernelUnavailable,
        )
        .toList();
    if (blocking.isNotEmpty) {
      e.status = ExtrudeStatus.invalid;
      e.diagnostics
        ..clear()
        ..addAll(blocking.map((i) => i.message));
      analytics.failures++;
      return ExtrudeExecutionResult(
        ExtrudeStatus.invalid,
        diagnostics: e.diagnostics,
      );
    }
    e.status = ExtrudeStatus.executing;
    final platformFeature = platformApi.engine.features[id]!,
        result = await FeatureKernelAdapter(projectId, kernel, extrudes)
            .execute(
              platformFeature,
              platform.FeatureContext(projectId: projectId, featureId: id),
            );
    final mapped = switch (result.state) {
      platform.FeatureExecutionState.ready => ExtrudeStatus.success,
      platform.FeatureExecutionState.kernelUnavailable =>
        ExtrudeStatus.kernelUnavailable,
      platform.FeatureExecutionState.unsupported =>
        ExtrudeStatus.unsupportedOperation,
      _ => ExtrudeStatus.failed,
    };
    e.status = mapped;
    e.output = result.outputs.firstOrNull?.handle as ShapeHandle?;
    e.diagnostics
      ..clear()
      ..addAll(result.diagnostics);
    platformFeature
      ..state = result.state
      ..result = result;
    analytics.rebuilds++;
    if (mapped == ExtrudeStatus.success) {
      analytics.successes++;
      analytics.kernelAvailable++;
    } else {
      analytics.failures++;
    }
    history.record(
      mapped == ExtrudeStatus.success
          ? ExtrudeHistoryAction.confirm
          : ExtrudeHistoryAction.failure,
      id,
    );
    return ExtrudeExecutionResult(
      mapped,
      shape: e.output,
      diagnostics: e.diagnostics,
    );
  }

  void updateParameters(String id, void Function(ExtrudeParameters) p) {
    final e = extrudes[id] ?? (throw StateError('Unknown extrude: $id'));
    p(e.parameters);
    e.version++;
    e.status = ExtrudeStatus.prepared;
    platformApi.engine.markDirty(id);
    analytics.parameterUpdates++;
    history.record(ExtrudeHistoryAction.edit, id);
  }

  void addDependency(String id, String parent) {
    final e = extrudes[id] ?? (throw StateError('Unknown extrude: $id'));
    graph.connect(parent, id);
    e.dependencies.add(parent);
    final platformFeature = platformApi.engine.features[id]!;
    if (!platformFeature.dependencies.contains(parent)) {
      platformFeature.dependencies.add(parent);
    }
    final platformGraphs = platformApi.engine.graphs;
    platformGraphs.dependencies.connect(parent, id);
    platformGraphs.execution.connect(parent, id);
    platformGraphs.parents.connect(parent, id);
    platformGraphs.children.connect(parent, id);
    platformGraphs.impact.connect(parent, id);
    analytics.dependencyUpdates++;
    platformApi.engine.markDirty(id);
  }

  Future<ExtrudeExecutionResult> rebuild(String id) async {
    final w = Stopwatch()..start();
    final r = await confirm(id);
    w.stop();
    analytics.totalRebuildMicros += w.elapsedMicroseconds;
    history.record(ExtrudeHistoryAction.rebuild, id);
    return r;
  }

  void rollback(String id) {
    final e = extrudes[id] ?? (throw StateError('Unknown extrude: $id'));
    e.output = null;
    e.status = ExtrudeStatus.rolledBack;
    analytics.rollback++;
    history.record(ExtrudeHistoryAction.rollback, id);
  }

  void suppress(String id, bool value) {
    final e = extrudes[id] ?? (throw StateError('Unknown extrude: $id'));
    e.status = value ? ExtrudeStatus.suppressed : ExtrudeStatus.prepared;
    platformApi.engine.suppress(id, value);
    history.record(
      value ? ExtrudeHistoryAction.suppress : ExtrudeHistoryAction.unsuppress,
      id,
    );
  }

  ExtrudeValidationResult validate(String id) {
    final e = extrudes[id] ?? (throw StateError('Unknown extrude: $id'));
    return validator.validate(e, profiles.profiles, kernel.descriptor);
  }

  ExtrudeQuality quality(String id) => ExtrudeQualityEvaluator().evaluate(
    extrudes[id] ?? (throw StateError('Unknown extrude: $id')),
    validate(id),
  );
  List<ExtrudeRecommendation> recommendations(String id) =>
      ExtrudeAdvisor().analyze(
        extrudes[id] ?? (throw StateError('Unknown extrude: $id')),
        validate(id),
      );
  bool undo() {
    if (_undo.isEmpty) return false;
    final c = _undo.removeLast();
    c.undo();
    _redo.add(c);
    analytics.undo++;
    history.record(ExtrudeHistoryAction.undo, 'extrude');
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    final c = _redo.removeLast();
    c.redo();
    _undo.add(c);
    analytics.redo++;
    history.record(ExtrudeHistoryAction.redo, 'extrude');
    return true;
  }

  void _record(_ExtrudeChange c) {
    _undo.add(c);
    _redo.clear();
  }

  Future<void> persist() => repository.save(
    extrudes: extrudes.values,
    history: history,
    analytics: analytics,
    previews: previews.values,
  );
}

class _ExtrudeChange {
  const _ExtrudeChange(this.undo, this.redo);
  final void Function() undo, redo;
}
