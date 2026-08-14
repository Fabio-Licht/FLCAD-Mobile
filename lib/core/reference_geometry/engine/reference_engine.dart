import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../advisor/reference_advisor.dart';
import '../analytics/reference_analytics.dart';
import '../graph/reference_graph.dart';
import '../history/reference_history.dart';
import '../integration/reference_kernel_adapter.dart';
import '../models/reference_models.dart';
import '../preview/reference_preview.dart';
import '../repository/reference_repository.dart';
import '../runtime/reference_runtime.dart';
import '../validation/reference_quality.dart';
import '../validation/reference_validation.dart';

class ReferenceEngine {
  ReferenceEngine({
    required this.projectId,
    required this.kernel,
    required this.repository,
    ReferenceRuntime? runtime,
    ReferenceAnalytics? analytics,
    ReferenceHistory? history,
  }) : runtime = runtime ?? ReferenceRuntime(),
       analytics = analytics ?? ReferenceAnalytics(),
       history = history ?? ReferenceHistory();
  final String projectId;
  final GeometryKernelAPI kernel;
  final ReferenceRepository repository;
  final ReferenceRuntime runtime;
  final ReferenceAnalytics analytics;
  final ReferenceHistory history;
  final graph = ReferenceGraph();
  final Map<String, ReferenceEntity> references = {};
  final Map<String, ReferencePreview> previews = {};
  final _undo = <_Change>[], _redo = <_Change>[];
  final validator = const ReferenceValidator();
  ReferenceEntity create({
    required ReferenceType type,
    required ReferenceMethod method,
    required String name,
    ReferenceInput? input,
    ReferenceParameters? parameters,
  }) {
    final entity = ReferenceEntity(
      type: type,
      method: method,
      name: name,
      input: input ?? ReferenceInput(),
      parameters: parameters ?? ReferenceParameters(),
    )..order = references.length;
    references[entity.id] = entity;
    graph.add(entity.id);
    _count(type);
    history.record(ReferenceHistoryAction.create, entity.id);
    _record(_Change(() => _remove(entity.id), () => _restore(entity)));
    return entity;
  }

  void _count(ReferenceType type) {
    if ({
      ReferenceType.datumPlane,
      ReferenceType.constructionPlane,
    }.contains(type)) {
      analytics.planes++;
    } else if ({
      ReferenceType.datumAxis,
      ReferenceType.constructionAxis,
    }.contains(type)) {
      analytics.axes++;
    } else if ({
      ReferenceType.datumPoint,
      ReferenceType.constructionPoint,
    }.contains(type)) {
      analytics.points++;
    } else if (type == ReferenceType.coordinateSystem) {
      analytics.coordinateSystems++;
    }
  }

  void _remove(String id) {
    references.remove(id);
    previews.remove(id);
    graph.remove(id);
  }

  void _restore(ReferenceEntity entity) {
    references[entity.id] = entity;
    graph.add(entity.id);
  }

  void edit(String id, void Function(ReferenceEntity) change) {
    final entity = _get(id);
    if (entity.frozen) throw StateError('Reference is frozen: $id');
    change(entity);
    entity.version++;
    entity.status = ReferenceStatus.prepared;
    history.record(ReferenceHistoryAction.edit, id);
  }

  void delete(String id) {
    final entity = _get(id);
    _remove(id);
    history.record(ReferenceHistoryAction.delete, id);
    _record(_Change(() => _restore(entity), () => _remove(id)));
  }

  void rename(String id, String name) {
    edit(id, (e) => e.name = name);
    history.record(ReferenceHistoryAction.rename, id);
  }

  void move(String id, int order) {
    edit(id, (e) => e.order = order);
    history.record(ReferenceHistoryAction.move, id);
  }

  void suppress(String id, bool value) {
    final e = _get(id);
    e.status = value ? ReferenceStatus.suppressed : ReferenceStatus.prepared;
    history.record(
      value
          ? ReferenceHistoryAction.suppress
          : ReferenceHistoryAction.unsuppress,
      id,
    );
  }

  void freeze(String id, bool value) {
    final e = _get(id);
    e.frozen = value;
    e.status = value ? ReferenceStatus.frozen : ReferenceStatus.prepared;
    history.record(
      value ? ReferenceHistoryAction.freeze : ReferenceHistoryAction.unfreeze,
      id,
    );
  }

  void group(String id, String? groupId) {
    _get(id).groupId = groupId;
    history.record(ReferenceHistoryAction.group, id);
  }

  void setVisibility(String id, bool value) {
    _get(id).visible = value;
    analytics.visibilityChanges++;
    history.record(ReferenceHistoryAction.visibility, id);
  }

  void addDependency(String id, String parent) {
    final e = _get(id);
    graph.connect(parent, id);
    if (!e.dependencies.contains(parent)) e.dependencies.add(parent);
    analytics.dependencyUpdates++;
  }

  ReferencePreview preview(String id) {
    final e = _get(id), p = const ReferencePreviewEngine().create(e);
    previews[id] = p;
    e.status = ReferenceStatus.previewed;
    history.record(ReferenceHistoryAction.preview, id);
    return p;
  }

  ReferenceValidationResult validate(String id, {bool kernelHealthy = true}) =>
      validator.validate(
        _get(id),
        kernel.descriptor,
        kernelHealthy: kernelHealthy,
      );
  Future<ReferenceExecutionResult> confirm(String id) async {
    final e = _get(id),
        health = await kernel.healthCheck(),
        result = validate(
          id,
          kernelHealthy: health.status != KernelHealthStatus.unavailable,
        ),
        blocking = result.issues
            .where(
              (i) =>
                  i.type != ReferenceIssueType.kernelUnavailable &&
                  i.type != ReferenceIssueType.unsupportedOperation,
            )
            .toList();
    if (blocking.isNotEmpty) {
      e.status = ReferenceStatus.invalid;
      e.diagnostics
        ..clear()
        ..addAll(blocking.map((i) => i.message));
      analytics.failures++;
      return ReferenceExecutionResult(
        ReferenceStatus.invalid,
        diagnostics: e.diagnostics,
      );
    }
    e.status = ReferenceStatus.executing;
    final execution = await ReferenceKernelAdapter(
      kernel,
    ).execute(projectId, e);
    e.status = execution.status;
    e.output = execution.shape;
    e.diagnostics
      ..clear()
      ..addAll(execution.diagnostics);
    analytics.rebuilds++;
    if (execution.success) {
      analytics.successes++;
    } else {
      analytics.failures++;
    }
    history.record(
      execution.success
          ? ReferenceHistoryAction.confirm
          : ReferenceHistoryAction.failure,
      id,
    );
    return execution;
  }

  Future<ReferenceExecutionResult> rebuild(String id) async {
    final watch = Stopwatch()..start(), result = await confirm(id);
    watch.stop();
    analytics.totalMicros += watch.elapsedMicroseconds;
    history.record(ReferenceHistoryAction.rebuild, id);
    return result;
  }

  ReferenceQuality quality(String id) =>
      const ReferenceQualityEngine().evaluate(_get(id), validate(id));
  List<ReferenceRecommendation> recommendations(String id) =>
      const ReferenceAdvisor().analyze(_get(id), validate(id));
  bool undo() {
    if (_undo.isEmpty) return false;
    final c = _undo.removeLast();
    c.undo();
    _redo.add(c);
    analytics.undo++;
    history.record(ReferenceHistoryAction.undo, 'reference');
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    final c = _redo.removeLast();
    c.redo();
    _undo.add(c);
    analytics.redo++;
    history.record(ReferenceHistoryAction.redo, 'reference');
    return true;
  }

  void _record(_Change c) {
    _undo.add(c);
    _redo.clear();
  }

  ReferenceEntity _get(String id) =>
      references[id] ?? (throw StateError('Unknown reference: $id'));
  Future<void> persist() => repository.save(
    references: references.values,
    history: history,
    analytics: analytics,
    previews: previews.values,
  );
}

class _Change {
  const _Change(this.undo, this.redo);
  final void Function() undo, redo;
}
