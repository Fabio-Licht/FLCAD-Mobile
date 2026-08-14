import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../advisor/reconstruction_advisor.dart';
import '../analytics/reconstruction_analytics.dart';
import '../graph/reconstruction_graph_builder.dart';
import '../integration/live_reconstruction_integration.dart';
import '../models/live_reconstruction_models.dart';
import '../repository/live_reconstruction_repository.dart';
import '../scheduler/incremental_scheduler.dart';
import '../updates/affected_objects_calculator.dart';
import '../validation/reconstruction_validation.dart';

class LiveReconstructionEngine {
  LiveReconstructionEngine({
    required this.operations,
    required this.repository,
    this.integration,
  });
  final SurfaceOperationsApi operations;
  final LiveReconstructionRepository repository;
  final LiveReconstructionIntegration? integration;
  final analytics = LiveReconstructionAnalytics();
  final _graph = const ReconstructionGraphBuilder();
  final _affected = const AffectedObjectsCalculator();
  final _scheduler = const IncrementalScheduler();
  final _validator = const ReconstructionValidator();
  final _advisor = const ReconstructionAdvisor();
  final Map<String, Map<String, String>> _surfaceBaselines = {};

  LiveReconstruction begin(
    SurfaceOperation operation,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    if (operation.preview == null) {
      throw StateError('Surface operation preview is required');
    }
    final graph = _graph.build(topology, quality);
    final value = LiveReconstruction(
      id: 'live-reconstruction:${IdGenerator.generate()}',
      operation: operation,
      graph: graph,
      state: ReconstructionState.created,
      timeline: [_event('created')],
      analytics: _snapshot(
        Duration.zero,
        const AffectedObjects(
          regions: {},
          patches: {},
          boundaries: {},
          continuity: {},
          validation: {},
          analytics: {},
          reflection: {},
          zebra: {},
          draft: {},
          heatMap: {},
        ),
      ),
      advice: const [],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    _surfaceBaselines[value.id] = {
      for (final patch in topology.patches)
        if (patch.surface.handle != null)
          patch.id: patch.surface.handle!.persistentId,
    };
    analytics.pipelines++;
    return value;
  }

  LiveReconstruction preview(String id, SurfaceQualityReport quality) {
    final value = _get(id);
    _require(value, const [ReconstructionState.created]);
    final affected = _affected.calculate(value.operation, value.graph);
    final original = {
      for (final patch in affected.patches)
        patch:
            _surfaceBaselines[value.id]?[patch] ??
            (throw StateError('Missing native surface baseline: $patch')),
    };
    final next = value.copyWith(
      state: ReconstructionState.previewed,
      preview: ReconstructionPreview(
        id: 'reconstruction-preview:${IdGenerator.generate()}',
        operationId: value.operation.id,
        affected: affected,
        originalSurfaceIds: original,
        createdAt: DateTime.now().toUtc(),
      ),
      timeline: [...value.timeline, _event('previewed')],
      advice: _advisor.advise(affected, quality),
      analytics: _snapshot(Duration.zero, affected),
    );
    return _save(next);
  }

  LiveReconstruction validate(String id) {
    final value = _get(id);
    _require(value, const [ReconstructionState.previewed]);
    final result = _validator.validate(value);
    if (!result.valid) {
      analytics.validationErrors += result.errors.length;
    }
    final next = value.copyWith(
      state: result.valid
          ? ReconstructionState.validated
          : ReconstructionState.failed,
      validation: result,
      timeline: [
        ...value.timeline,
        _event(result.valid ? 'validated' : 'validation-failed'),
      ],
      analytics: _snapshot(Duration.zero, value.preview!.affected),
    );
    return _save(next);
  }

  LiveReconstruction update(String id) {
    final value = _get(id);
    _require(value, const [ReconstructionState.validated]);
    if (value.validation?.valid != true) {
      throw StateError('Incremental update validation failed');
    }
    final watch = Stopwatch()..start();
    final scheduled = _scheduler.schedule(value.preview!.affected).toSet();
    if (scheduled.any((item) => !value.preview!.affected.all.contains(item))) {
      throw StateError('Scheduler escaped affected scope');
    }
    watch.stop();
    analytics.updates++;
    analytics.totalUpdateTime += watch.elapsed;
    final next = value.copyWith(
      state: ReconstructionState.updated,
      updatedObjects: Set.unmodifiable(scheduled),
      timeline: [...value.timeline, _event('incrementally-updated')],
      analytics: _snapshot(watch.elapsed, value.preview!.affected),
    );
    return _save(next);
  }

  Future<LiveReconstruction> commit(
    String id, {
    required String projectId,
    required SurfaceQualityReport quality,
  }) async {
    final value = _get(id);
    _require(value, const [ReconstructionState.updated]);
    final operation = await operations.commit(
      value.operation.id,
      projectId: projectId,
      quality: quality,
    );
    if (operation.status == SurfaceOperationStatus.unsupported) {
      return _save(
        value.copyWith(
          operation: operation,
          state: ReconstructionState.unsupported,
          timeline: [...value.timeline, _event('unsupported')],
          analytics: _snapshot(Duration.zero, value.preview!.affected),
        ),
      );
    }
    if (operation.status != SurfaceOperationStatus.committed) {
      throw StateError('Surface operation did not commit');
    }
    analytics.commits++;
    return _save(
      value.copyWith(
        operation: operation,
        state: ReconstructionState.committed,
        timeline: [...value.timeline, _event('committed')],
        analytics: _snapshot(Duration.zero, value.preview!.affected),
      ),
    );
  }

  Future<LiveReconstruction> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      ReconstructionState.previewed,
      ReconstructionState.validated,
      ReconstructionState.updated,
      ReconstructionState.committed,
    ]);
    var operation = value.operation;
    if (value.state == ReconstructionState.committed) {
      operation = await operations.rollback(operation.id);
    }
    analytics.rollbacks++;
    return _save(
      value.copyWith(
        operation: operation,
        state: ReconstructionState.rolledBack,
        updatedObjects: const {},
        timeline: [...value.timeline, _event('rolled-back')],
        analytics: _snapshot(Duration.zero, value.preview!.affected),
      ),
    );
  }

  LiveReconstruction cancel(String id) {
    final value = _get(id);
    _require(value, const [
      ReconstructionState.created,
      ReconstructionState.previewed,
      ReconstructionState.validated,
      ReconstructionState.updated,
      ReconstructionState.failed,
      ReconstructionState.unsupported,
    ]);
    final operation = operations.cancel(value.operation.id);
    analytics.cancellations++;
    return _save(
      value.copyWith(
        operation: operation,
        state: ReconstructionState.cancelled,
        updatedObjects: const {},
        timeline: [...value.timeline, _event('cancelled')],
        analytics: _snapshot(
          Duration.zero,
          value.preview?.affected ?? _emptyAffected,
        ),
      ),
    );
  }

  static const _emptyAffected = AffectedObjects(
    regions: {},
    patches: {},
    boundaries: {},
    continuity: {},
    validation: {},
    analytics: {},
    reflection: {},
    zebra: {},
    draft: {},
    heatMap: {},
  );
  Map<String, dynamic> _event(String event) => {
    'event': event,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
  LiveReconstruction _get(String id) =>
      repository.reconstructions[id] ??
      (throw StateError('Unknown live reconstruction: $id'));
  LiveReconstruction _save(LiveReconstruction value) {
    repository.update(value);
    integration?.onReconstructionUpdated(value);
    return value;
  }

  void _require(LiveReconstruction value, List<ReconstructionState> states) {
    if (!states.contains(value.state)) {
      throw StateError(
        'Invalid reconstruction transition: ${value.state.name}',
      );
    }
  }

  ReconstructionAnalytics _snapshot(
    Duration elapsed,
    AffectedObjects affected,
  ) => ReconstructionAnalytics(
    updateTime: elapsed,
    affectedObjects: affected.all.length,
    patches: affected.patches.length,
    boundaries: affected.boundaries.length,
    continuityUpdates: affected.continuity.length,
    validationUpdates: affected.validation.length,
    rollbacks: analytics.rollbacks,
    cancellations: analytics.cancellations,
    commits: analytics.commits,
  );
}
