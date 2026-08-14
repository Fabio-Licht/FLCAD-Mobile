import '../../live_reconstruction/api/live_reconstruction_api.dart';
import '../../live_reconstruction/models/live_reconstruction_models.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../advisor/morph_advisor.dart';
import '../analytics/morph_analytics.dart';
import '../anchors/anchor_engine.dart';
import '../integration/surface_morph_integration.dart';
import '../models/surface_morph_models.dart';
import '../repository/surface_morph_repository.dart';
import '../validation/morph_validation.dart';

class SurfaceMorphEngine {
  SurfaceMorphEngine({
    required this.operations,
    required this.reconstruction,
    required this.repository,
    this.integration,
  });
  final SurfaceOperationsApi operations;
  final LiveReconstructionApi reconstruction;
  final SurfaceMorphRepository repository;
  final SurfaceMorphIntegration? integration;
  final analytics = SurfaceMorphAnalytics();
  final _anchors = const AnchorEngine(),
      _influence = const InfluenceEngine(),
      _validator = const MorphValidator(),
      _advisor = const MorphAdvisor();

  MorphSession begin({
    required MorphTool tool,
    required PatchEntity patch,
    required List<MorphAnchor> anchors,
    required double radius,
    required FalloffType falloff,
    List<MorphConstraintGroup> constraintGroups = const [],
    Map<String, dynamic> parameters = const {},
  }) {
    if (patch.surface.handle == null) {
      throw StateError('Morph requires a native surface handle');
    }
    _anchors.validate(anchors);
    final value = MorphSession(
      id: 'surface-morph:${IdGenerator.generate()}',
      tool: tool,
      targetPatch: patch,
      anchors: List.unmodifiable(anchors),
      constraintGroups: List.unmodifiable(constraintGroups),
      radius: radius,
      falloff: falloff,
      parameters: Map.unmodifiable(parameters),
      status: MorphStatus.created,
      history: [_event('created')],
      analytics: _snapshot(Duration.zero, anchors.length, 0),
      advice: const [],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    analytics.operations++;
    analytics.anchors += anchors.length;
    return value;
  }

  MorphSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality, {
    List<double> customCurve = const [],
  }) {
    final value = _get(id);
    _require(value, const [MorphStatus.created]);
    final watch = Stopwatch()..start(),
        influence = _influence.calculate(
          value.anchors,
          value.radius,
          value.falloff,
          customCurve: customCurve,
        );
    final affectedPatches = <String>{
          value.targetPatch.id,
          ...value.targetPatch.adjacentPatchIds,
        }.toList(),
        affectedBoundaries = <String>{
          ...value.targetPatch.boundaryIds,
        }.toList();
    watch.stop();
    analytics.totalTime += watch.elapsed;
    analytics.influencedRegions += affectedPatches.length;
    final next = value.copyWith(
      status: MorphStatus.previewed,
      preview: MorphPreview(
        id: 'morph-preview:${IdGenerator.generate()}',
        originalSurfaceId: value.targetPatch.surface.handle!.persistentId,
        affectedPatches: affectedPatches,
        affectedBoundaries: affectedBoundaries,
        influence: influence,
        createdAt: DateTime.now().toUtc(),
      ),
      history: [...value.history, _event('previewed')],
      analytics: _snapshot(
        watch.elapsed,
        value.anchors.length,
        affectedPatches.length,
      ),
      advice: _advisor.advise(value, quality),
    );
    return _save(next);
  }

  MorphSession validate(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [MorphStatus.previewed]);
    final result = _validator.validate(value, topology, quality);
    return _save(
      value.copyWith(
        status: result.valid ? MorphStatus.validated : MorphStatus.failed,
        validation: result,
        history: [
          ...value.history,
          _event(result.valid ? 'validated' : 'validation-failed'),
        ],
        advice: _advisor.advise(value, quality),
      ),
    );
  }

  Future<MorphSession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) async {
    final value = _get(id);
    _require(value, const [MorphStatus.validated]);
    if (value.validation?.valid != true) {
      throw StateError('Morph commit prohibited by validation');
    }
    final constraints = value.constraintGroups
        .expand((e) => e.constraints)
        .toList();
    var operation = operations.begin(
      type: _operation(value.tool),
      patch: value.targetPatch,
      parameters: {
        'morphTool': value.tool.name,
        'influence': value.preview!.influence.toJson(),
        ...value.parameters,
      },
      constraints: constraints,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    if (operation.validation?.valid != true) {
      throw StateError('Surface Operations rejected morph commit');
    }
    var live = reconstruction.begin(operation, topology, quality);
    live = reconstruction.preview(live.id, quality);
    live = reconstruction.validate(live.id);
    live = reconstruction.update(live.id);
    live = await reconstruction.commit(
      live.id,
      projectId: projectId,
      quality: quality,
    );
    if (live.state == ReconstructionState.unsupported) {
      return _save(
        value.copyWith(
          status: MorphStatus.unsupported,
          surfaceOperationId: operation.id,
          liveReconstructionId: live.id,
          diagnostic: live.operation.diagnostic,
          history: [...value.history, _event('unsupported')],
        ),
      );
    }
    if (live.state != ReconstructionState.committed) {
      throw StateError('Live Reconstruction did not commit morph');
    }
    analytics.commits++;
    return _save(
      value.copyWith(
        status: MorphStatus.committed,
        surfaceOperationId: operation.id,
        liveReconstructionId: live.id,
        diagnostic: live.operation.diagnostic,
        history: [...value.history, _event('committed')],
        analytics: _snapshot(
          value.analytics.executionTime,
          value.anchors.length,
          value.preview!.affectedPatches.length,
        ),
      ),
    );
  }

  Future<MorphSession> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      MorphStatus.previewed,
      MorphStatus.validated,
      MorphStatus.committed,
    ]);
    if (value.status == MorphStatus.committed) {
      await reconstruction.rollback(value.liveReconstructionId!);
    }
    analytics.rollbacks++;
    return _save(
      value.copyWith(
        status: MorphStatus.rolledBack,
        history: [...value.history, _event('rolled-back')],
        analytics: _snapshot(
          value.analytics.executionTime,
          value.anchors.length,
          value.preview?.affectedPatches.length ?? 0,
        ),
      ),
    );
  }

  MorphSession cancel(String id) {
    final value = _get(id);
    _require(value, const [
      MorphStatus.created,
      MorphStatus.previewed,
      MorphStatus.validated,
      MorphStatus.failed,
      MorphStatus.unsupported,
    ]);
    analytics.cancellations++;
    return _save(
      value.copyWith(
        status: MorphStatus.cancelled,
        history: [...value.history, _event('cancelled')],
        analytics: _snapshot(
          value.analytics.executionTime,
          value.anchors.length,
          value.preview?.affectedPatches.length ?? 0,
        ),
      ),
    );
  }

  SurfaceOperationType _operation(MorphTool tool) => switch (tool) {
    MorphTool.match => SurfaceOperationType.matchSurface,
    MorphTool.relax || MorphTool.fair => SurfaceOperationType.healingOperation,
    _ => SurfaceOperationType.moveBoundary,
  };
  MorphSession _get(String id) =>
      repository.sessions[id] ??
      (throw StateError('Unknown morph session: $id'));
  MorphSession _save(MorphSession value) {
    repository.update(value);
    integration?.onMorphUpdated(value);
    return value;
  }

  void _require(MorphSession value, List<MorphStatus> states) {
    if (!states.contains(value.status)) {
      throw StateError('Invalid morph transition: ${value.status.name}');
    }
  }

  Map<String, dynamic> _event(String event) => {
    'event': event,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
  MorphAnalytics _snapshot(Duration elapsed, int anchors, int regions) =>
      MorphAnalytics(
        executionTime: elapsed,
        anchorCount: anchors,
        influencedRegions: regions,
        rollbacks: analytics.rollbacks,
        commits: analytics.commits,
        cancellations: analytics.cancellations,
      );
}
