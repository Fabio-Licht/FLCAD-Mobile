import '../../surface_boundary/constraints/boundary_constraint_solver.dart';
import '../../surface_boundary/models/surface_boundary_models.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_manufacturing/models/surface_manufacturing_models.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../constraints/advanced_surface_constraint_solver.dart';
import '../models/advanced_surface_models.dart';
import '../repository/advanced_surface_repository.dart';
import '../validation/advanced_surface_validation.dart';

class AdvancedSurfaceEngine {
  AdvancedSurfaceEngine({required this.operations, required this.repository})
    : validator = const AdvancedSurfaceValidator(
        AdvancedSurfaceConstraintSolver(BoundaryConstraintSolver()),
      );
  final SurfaceOperationsApi operations;
  final AdvancedSurfaceRepository repository;
  final AdvancedSurfaceValidator validator;
  int previews = 0,
      matchAnalyses = 0,
      gapAnalyses = 0,
      networkAnalyses = 0,
      validations = 0,
      commits = 0,
      rollbacks = 0,
      cancellations = 0;

  AdvancedSurfaceSession begin({
    required AdvancedSurfaceType type,
    required PatchEntity targetPatch,
    List<PatchEntity> selectedPatches = const [],
    AdvancedSelectionType selectionType = AdvancedSelectionType.patch,
    AdvancedContinuity continuity = AdvancedContinuity.g1,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<BoundaryFixedRegion> fixedRegions = const [],
    ManufacturingIntent? manufacturingIntent,
  }) {
    if (targetPatch.surface.handle == null) {
      throw StateError('Advanced surface operation requires a native handle');
    }
    if (continuity == AdvancedContinuity.g3) {
      throw UnsupportedError(
        'G3 infrastructure is reserved but not implemented',
      );
    }
    final selection = selectedPatches.isEmpty ? [targetPatch] : selectedPatches;
    final value = AdvancedSurfaceSession(
      id: 'advanced-surface:${IdGenerator.generate()}',
      type: type,
      targetPatch: targetPatch,
      selectedPatches: List.unmodifiable(selection),
      selectionType: selectionType,
      continuity: continuity,
      parameters: Map.unmodifiable(parameters),
      constraints: List.unmodifiable(constraints),
      fixedRegions: List.unmodifiable(fixedRegions),
      manufacturingIntent: manufacturingIntent,
      status: AdvancedSurfaceStatus.created,
      history: [_event('created')],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    return value;
  }

  AdvancedSurfaceSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [AdvancedSurfaceStatus.created]);
    final selectedIds = value.selectedPatches.map((e) => e.id).toSet();
    final selectedQuality = quality.patchQualities
        .where((e) => selectedIds.contains(e.patch.id))
        .toList();
    final qualityScore = selectedQuality.isEmpty
        ? 0.0
        : selectedQuality.map((e) => e.overall).reduce((a, b) => a + b) /
              selectedQuality.length;
    final relevantContinuity = quality.continuity
        .where(
          (e) =>
              selectedIds.contains(e.firstPatchId) ||
              selectedIds.contains(e.secondPatchId),
        )
        .toList();
    final continuityScore = relevantContinuity.isEmpty
        ? qualityScore
        : relevantContinuity
                  .where((e) => e.level != ContinuityLevel.notApplicable)
                  .length /
              relevantContinuity.length;
    final selectedBoundaries = topology.boundaries
        .where(
          (e) => value.selectedPatches.any((p) => p.boundaryIds.contains(e.id)),
        )
        .toList();
    final tolerance = ((value.parameters['tolerance'] ?? .01) as num)
        .toDouble()
        .abs();
    final open = selectedBoundaries
        .where((e) => e.type == BoundaryType.open)
        .map((e) => e.id)
        .toList();
    final unhealthy = selectedBoundaries
        .where((e) => e.health != TopologyHealth.healthy)
        .map((e) => e.id)
        .toList();
    final intersectionIds = value.selectedPatches
        .expand((e) => e.intersectionIds)
        .toSet();
    final gap = GapAnalysisResult(
      gaps: unhealthy,
      overlaps: topology.intersections
          .where((e) => intersectionIds.contains(e.id))
          .map((e) => e.id)
          .toList(),
      discontinuities: relevantContinuity
          .where((e) => e.discontinuity > tolerance)
          .map((e) => e.id)
          .toList(),
      openRegions: open,
      maximumGap: relevantContinuity.isEmpty
          ? 0
          : relevantContinuity
                .map((e) => e.maximumError)
                .reduce((a, b) => a > b ? a : b),
      withinTolerance: relevantContinuity.every(
        (e) => e.maximumError <= tolerance,
      ),
    );
    final distribution = <String, int>{};
    for (final patch in value.selectedPatches) {
      final key = patch.surface.primitiveType.name;
      distribution[key] = (distribution[key] ?? 0) + 1;
    }
    final reflection = selectedQuality.isEmpty
        ? 0.0
        : selectedQuality
                  .map((e) => e.reflectionScore)
                  .reduce((a, b) => a + b) /
              selectedQuality.length;
    final zebra = selectedQuality.isEmpty
        ? 0.0
        : selectedQuality.map((e) => e.zebra.contrast).reduce((a, b) => a + b) /
              selectedQuality.length;
    final manufacturing = selectedQuality.isEmpty
        ? 0.0
        : selectedQuality.map((e) => e.draftScore).reduce((a, b) => a + b) /
              selectedQuality.length;
    final network = SurfaceNetworkAnalysis(
      globalContinuity: continuityScore.clamp(0, 1),
      globalQuality: qualityScore.clamp(0, 1),
      patchDistribution: distribution,
      stress: (1 - qualityScore).clamp(0, 1),
      reflection: reflection.clamp(0, 1),
      zebra: zebra.clamp(0, 1),
      manufacturingScore: manufacturing.clamp(0, 1),
    );
    final preview = AdvancedSurfacePreview(
      affectedSurfaces: value.selectedPatches.map((e) => e.id).toList(),
      predictedQuality: qualityScore.clamp(0, 1),
      predictedContinuity: continuityScore.clamp(0, 1),
      gapAnalysis: gap,
      networkAnalysis: network,
    );
    previews++;
    gapAnalyses++;
    networkAnalyses++;
    if (value.type == AdvancedSurfaceType.match) matchAnalyses++;
    return _save(
      value.copyWith(
        status: AdvancedSurfaceStatus.previewed,
        preview: preview,
        advice: _advise(value, gap),
        history: [...value.history, _event('previewed')],
      ),
    );
  }

  AdvancedSurfaceSession validate(String id) {
    final value = _get(id);
    _require(value, const [AdvancedSurfaceStatus.previewed]);
    final result = validator.validate(value);
    validations++;
    return _save(
      value.copyWith(
        status: result.valid
            ? AdvancedSurfaceStatus.validated
            : AdvancedSurfaceStatus.failed,
        validation: result,
        history: [
          ...value.history,
          _event(result.valid ? 'validated' : 'validation-failed'),
        ],
      ),
    );
  }

  Future<AdvancedSurfaceSession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) async {
    final value = _get(id);
    _require(value, const [AdvancedSurfaceStatus.validated]);
    if (_consultative.contains(value.type)) {
      throw StateError('${value.type.name} is consultative and cannot commit');
    }
    final operationType = _operation(value.type);
    var operation = operations.begin(
      type: operationType,
      patch: value.targetPatch,
      parameters: {
        'advancedOperation': value.type.name,
        'selectedPatches': value.selectedPatches.map((e) => e.id).toList(),
        'selectionType': value.selectionType.name,
        'continuity': value.continuity.name,
        'fixedRegions': value.fixedRegions.map((e) => e.toJson()).toList(),
        'manufacturingIntent': value.manufacturingIntent?.toJson(),
        ...value.parameters,
      },
      constraints: value.constraints,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    if (operation.status != SurfaceOperationStatus.validated) {
      throw StateError(
        'Advanced surface commit prohibited by official validation',
      );
    }
    operation = await operations.commit(
      operation.id,
      projectId: projectId,
      quality: quality,
    );
    if (operation.status == SurfaceOperationStatus.unsupported) {
      return _save(
        value.copyWith(
          status: AdvancedSurfaceStatus.unsupported,
          operationId: operation.id,
          diagnostic:
              operation.diagnostic ??
              'UnsupportedOperation: ${operationType.name}',
          history: [...value.history, _event('unsupported')],
        ),
      );
    }
    commits++;
    return _save(
      value.copyWith(
        status: AdvancedSurfaceStatus.committed,
        operationId: operation.id,
        resultSurface: operation.resultSurface,
        diagnostic: operation.diagnostic,
        history: [...value.history, _event('committed')],
      ),
    );
  }

  Future<AdvancedSurfaceSession> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      AdvancedSurfaceStatus.previewed,
      AdvancedSurfaceStatus.validated,
      AdvancedSurfaceStatus.committed,
      AdvancedSurfaceStatus.unsupported,
    ]);
    if (value.status == AdvancedSurfaceStatus.committed) {
      await operations.rollback(value.operationId!);
    }
    rollbacks++;
    return _save(
      value.copyWith(
        status: AdvancedSurfaceStatus.rolledBack,
        history: [...value.history, _event('rolled-back')],
      ),
    );
  }

  AdvancedSurfaceSession cancel(String id) {
    final value = _get(id);
    _require(value, const [
      AdvancedSurfaceStatus.created,
      AdvancedSurfaceStatus.previewed,
      AdvancedSurfaceStatus.validated,
      AdvancedSurfaceStatus.failed,
      AdvancedSurfaceStatus.unsupported,
    ]);
    cancellations++;
    return _save(
      value.copyWith(
        status: AdvancedSurfaceStatus.cancelled,
        history: [...value.history, _event('cancelled')],
      ),
    );
  }

  static const _consultative = {
    AdvancedSurfaceType.gapAnalysis,
    AdvancedSurfaceType.networkOptimization,
    AdvancedSurfaceType.smartAdvisor,
  };
  SurfaceOperationType _operation(AdvancedSurfaceType type) => switch (type) {
    AdvancedSurfaceType.match => SurfaceOperationType.matchSurface,
    AdvancedSurfaceType.replace => SurfaceOperationType.replaceSurface,
    AdvancedSurfaceType.rebuild => SurfaceOperationType.rebuildSurface,
    AdvancedSurfaceType.heal => SurfaceOperationType.healSurface,
    AdvancedSurfaceType.stitch => SurfaceOperationType.stitchSurface,
    AdvancedSurfaceType.fill ||
    AdvancedSurfaceType.boundaryFill => SurfaceOperationType.fillSurface,
    AdvancedSurfaceType.gapClosure => SurfaceOperationType.gapClosure,
    _ => throw StateError('${type.name} has no mutating kernel operation'),
  };
  Map<String, dynamic> get analytics => {
    'operations': repository.sessions.length,
    'previews': previews,
    'matchAnalyses': matchAnalyses,
    'gapAnalyses': gapAnalyses,
    'networkAnalyses': networkAnalyses,
    'validations': validations,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'affectedSurfaces': repository.sessions.values
        .expand((e) => e.preview?.affectedSurfaces ?? const <String>[])
        .toSet()
        .length,
    'quality': repository.sessions.values
        .map((e) => e.preview?.predictedQuality)
        .whereType<double>()
        .toList(),
    'continuity': repository.sessions.values
        .map((e) => e.preview?.predictedContinuity)
        .whereType<double>()
        .toList(),
    'strategies': repository.sessions.values.map((e) => e.type.name).toList(),
  };
  AdvancedSurfaceAdvice _advise(
    AdvancedSurfaceSession value,
    GapAnalysisResult gap,
  ) => AdvancedSurfaceAdvice(
    strategy: value.type == AdvancedSurfaceType.smartAdvisor
        ? (gap.openRegions.isNotEmpty
              ? AdvancedSurfaceType.fill
              : gap.gaps.isNotEmpty
              ? AdvancedSurfaceType.heal
              : AdvancedSurfaceType.match)
        : value.type,
    recommendations: const [
      'Choose the lowest-loss strategy',
      'Preserve continuity and dimensional intent',
      'Improve global quality',
      'Retain references and constraints',
      'Prepare evidence for G-012',
    ],
  );
  AdvancedSurfaceSession _get(String id) =>
      repository.sessions[id] ??
      (throw StateError('Unknown advanced surface session: $id'));
  AdvancedSurfaceSession _save(AdvancedSurfaceSession value) {
    repository.update(value);
    return value;
  }

  void _require(
    AdvancedSurfaceSession value,
    List<AdvancedSurfaceStatus> allowed,
  ) {
    if (!allowed.contains(value.status)) {
      throw StateError(
        'Invalid advanced surface transition: ${value.status.name}',
      );
    }
  }

  Map<String, dynamic> _event(String event) => {
    'event': event,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
}
