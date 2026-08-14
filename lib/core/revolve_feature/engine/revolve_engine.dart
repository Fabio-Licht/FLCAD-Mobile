import 'dart:math' as math;
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../feature_modeling/models/feature_models.dart' as platform;
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../advisor/revolve_advisor.dart';
import '../analytics/revolve_analytics.dart';
import '../graph/revolve_graph.dart';
import '../history/revolve_history.dart';
import '../integration/revolve_kernel_adapter.dart';
import '../models/revolve_models.dart';
import '../preview/revolve_preview.dart';
import '../repository/revolve_repository.dart';
import '../runtime/revolve_runtime.dart';
import '../validation/revolve_quality.dart';
import '../validation/revolve_validation.dart';

class RevolveEngine {
  RevolveEngine({
    required this.projectId,
    required this.kernel,
    required this.profiles,
    required this.platformApi,
    required this.repository,
    RevolveRuntime? runtime,
    RevolveAnalytics? analytics,
    RevolveHistory? history,
  }) : runtime = runtime ?? RevolveRuntime(),
       analytics = analytics ?? RevolveAnalytics(),
       history = history ?? RevolveHistory();
  final String projectId;
  final GeometryKernelAPI kernel;
  final ProfileRecognitionApi profiles;
  final FeatureModelingApi platformApi;
  final RevolveRepository repository;
  final RevolveRuntime runtime;
  final RevolveAnalytics analytics;
  final RevolveHistory history;
  final graph = RevolveGraph();
  final Map<String, RevolveFeature> revolves = {};
  final Map<String, RevolvePreview> previews = {};
  final List<_RevolveChange> _undo = [], _redo = [];
  final validator = const RevolveValidator();
  RevolveFeature prepare(RevolveInput input, RevolveParameters parameters) {
    final r = RevolveFeature(input: input, parameters: parameters),
        feature = platform.FeatureInstance(
          id: r.id,
          definition: const platform.FeatureDefinition(
            type: platform.FeatureType.revolve,
            name: 'Professional Revolve',
            requiredInputs: ['profile', 'axis'],
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
            platform.FeatureInput(
              'axis',
              platform.FeatureReference(
                input.axis.referenceId ?? r.id,
                kind: 'axis',
              ),
            ),
          ],
          parameters: {...parameters.toJson(), 'axis': input.axis.toJson()},
        );
    r.platformFeatureId = feature.id;
    revolves[r.id] = r;
    graph.add(r.id);
    platformApi.engine.add(feature);
    analytics.revolves = revolves.length;
    analytics.totalAngle += parameters.angle;
    history.record(RevolveHistoryAction.create, r.id);
    _record(_RevolveChange(() => _remove(r.id), () => _restore(r, feature)));
    return r;
  }

  void _remove(String id) {
    revolves.remove(id);
    previews.remove(id);
    platformApi.engine.delete(id);
  }

  void _restore(RevolveFeature r, platform.FeatureInstance f) {
    revolves[r.id] = r;
    graph.add(r.id);
    platformApi.engine.add(f);
  }

  RevolvePreview preview(String id) {
    final r = revolves[id] ?? (throw StateError('Unknown revolve: $id')),
        selected = profiles.profiles
            .where((p) => r.input.profileIds.contains(p.id))
            .toList(),
        area = selected.fold<double>(0, (s, p) => s + p.area),
        radius = math.sqrt(area.abs()) / 2,
        value = RevolvePreviewEngine().create(
          r,
          profileArea: area,
          centroidRadius: radius,
          kernel: kernel.descriptor,
        );
    previews[id] = value;
    r.status = RevolveStatus.previewed;
    history.record(RevolveHistoryAction.preview, id);
    return value;
  }

  Future<RevolveExecutionResult> confirm(String id) async {
    final r = revolves[id] ?? (throw StateError('Unknown revolve: $id')),
        health = await kernel.healthCheck(),
        validation = validator.validate(
          r,
          profiles.profiles,
          kernel.descriptor,
          kernelHealthy: health.status != KernelHealthStatus.unavailable,
        ),
        blocking = validation.issues
            .where(
              (i) =>
                  i.type != RevolveValidationIssueType.unsupportedCapability &&
                  i.type != RevolveValidationIssueType.kernelUnavailable,
            )
            .toList();
    if (blocking.isNotEmpty) {
      r.status = RevolveStatus.invalid;
      r.diagnostics
        ..clear()
        ..addAll(blocking.map((i) => i.message));
      analytics.failures++;
      return RevolveExecutionResult(
        RevolveStatus.invalid,
        diagnostics: r.diagnostics,
      );
    }
    r.status = RevolveStatus.executing;
    final result = await RevolveFeatureKernelAdapter(
          kernel,
        ).execute(projectId, r),
        feature = platformApi.engine.features[id]!;
    r.status = result.status;
    r.output = result.shape;
    r.diagnostics
      ..clear()
      ..addAll(result.diagnostics);
    final state = switch (result.status) {
      RevolveStatus.success => platform.FeatureExecutionState.ready,
      RevolveStatus.kernelUnavailable =>
        platform.FeatureExecutionState.kernelUnavailable,
      RevolveStatus.unsupportedOperation =>
        platform.FeatureExecutionState.unsupported,
      _ => platform.FeatureExecutionState.failed,
    };
    feature.state = state;
    feature.result = platform.FeatureResult(
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
          ? RevolveHistoryAction.confirm
          : RevolveHistoryAction.failure,
      id,
    );
    return result;
  }

  void updateParameters(String id, void Function(RevolveParameters) p) {
    final r = revolves[id] ?? (throw StateError('Unknown revolve: $id'));
    p(r.parameters);
    r.version++;
    r.status = RevolveStatus.prepared;
    platformApi.engine.markDirty(id);
    analytics.parameterUpdates++;
    history.record(RevolveHistoryAction.edit, id);
  }

  void updateAxis(String id, void Function(RevolveAxis) a) {
    final r = revolves[id] ?? (throw StateError('Unknown revolve: $id'));
    a(r.input.axis);
    r.version++;
    r.status = RevolveStatus.prepared;
    platformApi.engine.markDirty(id);
    analytics.axisUpdates++;
    history.record(RevolveHistoryAction.axisUpdate, id);
  }

  void addDependency(String id, String parent) {
    final r = revolves[id] ?? (throw StateError('Unknown revolve: $id'));
    graph.connect(parent, id);
    if (!r.dependencies.contains(parent)) r.dependencies.add(parent);
    final f = platformApi.engine.features[id]!, g = platformApi.engine.graphs;
    if (!f.dependencies.contains(parent)) f.dependencies.add(parent);
    g.dependencies.connect(parent, id);
    g.execution.connect(parent, id);
    g.parents.connect(parent, id);
    g.children.connect(parent, id);
    g.impact.connect(parent, id);
    platformApi.engine.markDirty(id);
    analytics.dependencyUpdates++;
  }

  Future<RevolveExecutionResult> rebuild(String id) async {
    final w = Stopwatch()..start(), result = await confirm(id);
    w.stop();
    analytics.totalRebuildMicros += w.elapsedMicroseconds;
    history.record(RevolveHistoryAction.rebuild, id);
    return result;
  }

  void rollback(String id) {
    final r = revolves[id] ?? (throw StateError('Unknown revolve: $id'));
    r.output = null;
    r.status = RevolveStatus.rolledBack;
    analytics.rollbacks++;
    history.record(RevolveHistoryAction.rollback, id);
  }

  void suppress(String id, bool value) {
    final r = revolves[id] ?? (throw StateError('Unknown revolve: $id'));
    r.status = value ? RevolveStatus.suppressed : RevolveStatus.prepared;
    platformApi.engine.suppress(id, value);
    history.record(
      value ? RevolveHistoryAction.suppress : RevolveHistoryAction.unsuppress,
      id,
    );
  }

  RevolveValidationResult validate(String id) => validator.validate(
    revolves[id] ?? (throw StateError('Unknown revolve: $id')),
    profiles.profiles,
    kernel.descriptor,
  );
  RevolveQuality quality(String id) => const RevolveQualityEvaluator().evaluate(
    revolves[id] ?? (throw StateError('Unknown revolve: $id')),
    validate(id),
  );
  List<RevolveRecommendation> recommendations(String id) =>
      const RevolveAdvisor().analyze(
        revolves[id] ?? (throw StateError('Unknown revolve: $id')),
        validate(id),
      );
  bool undo() {
    if (_undo.isEmpty) return false;
    final c = _undo.removeLast();
    c.undo();
    _redo.add(c);
    analytics.undo++;
    history.record(RevolveHistoryAction.undo, 'revolve');
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    final c = _redo.removeLast();
    c.redo();
    _undo.add(c);
    analytics.redo++;
    history.record(RevolveHistoryAction.redo, 'revolve');
    return true;
  }

  void _record(_RevolveChange c) {
    _undo.add(c);
    _redo.clear();
  }

  Future<void> persist() => repository.save(
    revolves: revolves.values,
    history: history,
    analytics: analytics,
    previews: previews.values,
  );
}

class _RevolveChange {
  const _RevolveChange(this.undo, this.redo);
  final void Function() undo, redo;
}
