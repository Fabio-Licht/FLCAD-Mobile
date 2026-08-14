import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../advisor/alignment_advisor.dart';
import '../analytics/alignment_analytics.dart';
import '../graph/alignment_graph.dart';
import '../history/alignment_history.dart';
import '../integration/alignment_kernel_adapter.dart';
import '../models/alignment_models.dart';
import '../preview/alignment_preview.dart';
import '../repository/alignment_repository.dart';
import '../runtime/alignment_runtime.dart';
import '../validation/alignment_quality.dart';
import '../validation/alignment_validation.dart';

class AlignmentEngine {
  AlignmentEngine({
    required this.projectId,
    required this.kernel,
    required this.repository,
    AlignmentRuntime? runtime,
    AlignmentAnalytics? analytics,
    AlignmentHistory? history,
  }) : runtime = runtime ?? AlignmentRuntime(),
       analytics = analytics ?? AlignmentAnalytics(),
       history = history ?? AlignmentHistory();
  final String projectId;
  final GeometryKernelAPI kernel;
  final AlignmentRepository repository;
  final AlignmentRuntime runtime;
  final AlignmentAnalytics analytics;
  final AlignmentHistory history;
  final graph = AlignmentGraph();
  final Map<String, Alignment> alignments = {};
  final Map<String, AlignmentPreview> previews = {};
  final _undo = <_Change>[], _redo = <_Change>[];
  final validator = const AlignmentValidator();
  Alignment create(
    AlignmentType type,
    AlignmentInput input, {
    AlignmentParameters? parameters,
  }) {
    final a = Alignment(
      type: type,
      input: input,
      parameters: parameters ?? AlignmentParameters(),
    );
    alignments[a.id] = a;
    graph.add(a.id);
    for (
      var i = 0;
      i < input.movingReferences.length && i < input.fixedReferences.length;
      i++
    ) {
      graph.mapReference(
        a.id,
        input.movingReferences[i].id,
        input.fixedReferences[i].id,
      );
    }
    analytics.alignments++;
    if ({
      AlignmentType.bestFit,
      AlignmentType.localBestFit,
      AlignmentType.regionBestFit,
    }.contains(type)) {
      analytics.bestFits++;
    }
    if (type == AlignmentType.icp) analytics.icp++;
    history.record(AlignmentHistoryAction.create, a.id);
    _record(_Change(() => alignments.remove(a.id), () => alignments[a.id] = a));
    return a;
  }

  void update(String id, void Function(Alignment) change) {
    final a = _get(id);
    change(a);
    a.version++;
    a.status = AlignmentStatus.prepared;
    history.record(AlignmentHistoryAction.update, id);
  }

  void delete(String id) {
    final a = _get(id);
    alignments.remove(id);
    history.record(AlignmentHistoryAction.delete, id);
    _record(_Change(() => alignments[id] = a, () => alignments.remove(id)));
  }

  AlignmentPreview preview(String id) {
    final a = _get(id), p = const AlignmentPreviewEngine().create(a);
    previews[id] = p;
    a
      ..status = AlignmentStatus.previewed
      ..rms = p.rmsError
      ..maximumError = p.maximumError
      ..averageError = p.averageError
      ..confidence = p.confidence;
    analytics.previewUpdates++;
    return p;
  }

  void apply(String id) {
    final a = _get(id), p = preview(id);
    a.status = AlignmentStatus.applied;
    graph.recordTransform(id, p.matrix.values);
    history.record(AlignmentHistoryAction.apply, id, matrix: p.matrix.values);
  }

  void cancel(String id) {
    final a = _get(id);
    a.status = AlignmentStatus.cancelled;
    a.output = null;
    history.record(AlignmentHistoryAction.cancel, id);
  }

  AlignmentValidationResult validate(String id, {bool kernelHealthy = true}) =>
      validator.validate(
        _get(id),
        kernel.descriptor,
        kernelHealthy: kernelHealthy,
      );
  Future<AlignmentExecutionResult> commit(String id) async {
    final watch = Stopwatch()..start(),
        a = _get(id),
        health = await kernel.healthCheck(),
        validation = validate(
          id,
          kernelHealthy: health.status != KernelHealthStatus.unavailable,
        ),
        blocking = validation.issues
            .where(
              (e) =>
                  e.type != AlignmentIssueType.kernelUnavailable &&
                  e.type != AlignmentIssueType.unsupportedOperation,
            )
            .toList();
    if (blocking.isNotEmpty) {
      a.status = AlignmentStatus.invalid;
      a.diagnostics
        ..clear()
        ..addAll(blocking.map((e) => e.message));
      analytics.failures++;
      return AlignmentExecutionResult(
        AlignmentStatus.invalid,
        diagnostics: a.diagnostics,
      );
    }
    final result = await AlignmentKernelAdapter(kernel).commit(projectId, a);
    watch.stop();
    analytics.totalMicros += watch.elapsedMicroseconds;
    a.status = result.status;
    a.output = result.shape;
    a.diagnostics
      ..clear()
      ..addAll(result.diagnostics);
    if (result.success) {
      analytics.successes++;
      final accuracy = 1 - a.rms;
      analytics.totalAccuracy += accuracy;
      if (accuracy > analytics.maximumAccuracy) {
        analytics.maximumAccuracy = accuracy;
      }
    } else {
      analytics.failures++;
    }
    history.record(
      result.success
          ? AlignmentHistoryAction.commit
          : AlignmentHistoryAction.failure,
      id,
      matrix: a.parameters.matrix.values,
    );
    return result;
  }

  void rollback(String id) {
    final a = _get(id);
    a.output = null;
    a.status = AlignmentStatus.rolledBack;
    analytics.rollbacks++;
    history.record(AlignmentHistoryAction.rollback, id);
  }

  void replay(String id) {
    final matrices = graph.transformHistory[id];
    if (matrices == null || matrices.isEmpty) {
      throw StateError('No transform history: $id');
    }
    final a = _get(id);
    a.parameters.matrix = AlignmentMatrix(List.of(matrices.last));
    a.status = AlignmentStatus.applied;
    history.record(AlignmentHistoryAction.replay, id);
  }

  void addDependency(String id, String parent) {
    final a = _get(id);
    graph.connect(parent, id);
    if (!a.dependencies.contains(parent)) a.dependencies.add(parent);
    analytics.dependencyUpdates++;
  }

  void lockAxis(String id, String axis) =>
      _get(id).parameters.lockedAxes.add(axis);
  void unlockAxis(String id, String axis) =>
      _get(id).parameters.lockedAxes.remove(axis);
  AlignmentQuality quality(String id) => const AlignmentQualityEngine()
      .evaluate(_get(id), previews[id] ?? preview(id));
  List<AlignmentRecommendation> recommendations(String id) =>
      const AlignmentAdvisor().analyze(_get(id), previews[id] ?? preview(id));
  bool undo() {
    if (_undo.isEmpty) return false;
    final c = _undo.removeLast();
    c.undo();
    _redo.add(c);
    analytics.undo++;
    history.record(AlignmentHistoryAction.undo, 'alignment');
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    final c = _redo.removeLast();
    c.redo();
    _undo.add(c);
    analytics.redo++;
    history.record(AlignmentHistoryAction.redo, 'alignment');
    return true;
  }

  void _record(_Change c) {
    _undo.add(c);
    _redo.clear();
  }

  Alignment _get(String id) =>
      alignments[id] ?? (throw StateError('Unknown alignment: $id'));
  Future<void> persist() => repository.save(
    alignments: alignments.values,
    history: history,
    analytics: analytics,
    previews: previews.values,
    mappings: graph.referenceMappings,
  );
}

class _Change {
  const _Change(this.undo, this.redo);
  final void Function() undo, redo;
}
