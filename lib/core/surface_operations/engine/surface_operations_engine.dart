import '../../cad_kernel/io/kernel_io_models.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../advisor/surface_operation_advisor.dart';
import '../analytics/surface_operation_analytics.dart';
import '../constraints/surface_constraint_solver.dart';
import '../integration/surface_operations_integration.dart';
import '../models/surface_operation_models.dart';
import '../repository/surface_operation_repository.dart';
import '../validation/surface_operation_validation.dart';

class SurfaceOperationsEngine {
  SurfaceOperationsEngine({
    required this.kernel,
    required this.repository,
    this.integration,
  }) : validator = const SurfaceOperationValidator(SurfaceConstraintSolver());
  final SurfaceOperationKernelAPI kernel;
  final SurfaceOperationRepository repository;
  final SurfaceOperationsIntegration? integration;
  final SurfaceOperationValidator validator;
  final analytics = SurfaceOperationsAnalytics();
  final advisor = const SurfaceOperationAdvisor();

  SurfaceOperation begin({
    required SurfaceOperationType type,
    required PatchEntity patch,
    required Map<String, dynamic> parameters,
    List<SurfaceConstraint> constraints = const [],
  }) {
    final handle = patch.surface.handle;
    if (handle == null) {
      throw StateError('Surface operation requires a native surface handle');
    }
    final value = SurfaceOperation(
      id: 'surface-operation:${IdGenerator.generate()}',
      type: type,
      targetPatch: patch,
      targetSurface: handle,
      constraints: List.unmodifiable(constraints),
      parameters: Map.unmodifiable(parameters),
      status: SurfaceOperationStatus.created,
      createdAt: DateTime.now().toUtc(),
      executionTime: Duration.zero,
      analytics: _snapshot(),
    );
    repository.add(value);
    analytics.operations++;
    return value;
  }

  SurfaceOperation preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [SurfaceOperationStatus.created]);
    final patch = value.targetPatch;
    final continuity = quality.continuity
        .where((e) => e.firstPatchId == patch.id || e.secondPatchId == patch.id)
        .map((e) => e.id)
        .toList();
    final next = value.copyWith(
      preview: SurfaceOperationPreview(
        id: 'preview:${IdGenerator.generate()}',
        operationId: id,
        originalSurface: value.targetSurface,
        affectedPatches: [patch.id, ...patch.adjacentPatchIds],
        affectedBoundaries: patch.boundaryIds,
        affectedContinuity: continuity,
        kernelStatus: 'Pending commit capability check',
        createdAt: DateTime.now().toUtc(),
      ),
      status: SurfaceOperationStatus.previewed,
      analytics: _snapshot(),
    );
    repository.update(next, 'previewed');
    integration?.onOperationUpdated(next, advisor.advise(next, quality));
    return next;
  }

  SurfaceOperation validate(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [SurfaceOperationStatus.previewed]);
    final result = validator.validate(value, topology, quality);
    if (!result.valid) {
      analytics.validationErrors += result.errors.length;
    }
    final next = value.copyWith(
      validation: result,
      status: result.valid
          ? SurfaceOperationStatus.validated
          : SurfaceOperationStatus.failed,
      analytics: _snapshot(),
    );
    repository.update(next, result.valid ? 'validated' : 'validation-failed');
    integration?.onOperationUpdated(next, advisor.advise(next, quality));
    return next;
  }

  Future<SurfaceOperation> commit(
    String id, {
    required String projectId,
    required SurfaceQualityReport quality,
  }) async {
    final value = _get(id);
    _require(value, const [SurfaceOperationStatus.validated]);
    if (value.validation?.valid != true) {
      throw StateError('Commit prohibited: operation validation failed');
    }
    final watch = Stopwatch()..start();
    final result = await kernel.executeSurfaceOperation(
      value.targetSurface,
      value.type.name,
      value.parameters,
      projectId: projectId,
    );
    watch.stop();
    analytics.totalExecution += watch.elapsed;
    if (!result.supported) {
      final unsupported = value.copyWith(
        status: SurfaceOperationStatus.unsupported,
        executionTime: watch.elapsed,
        diagnostic: result.diagnostic,
        analytics: _snapshot(),
      );
      repository.update(unsupported, 'unsupported');
      integration?.onOperationUpdated(
        unsupported,
        advisor.advise(unsupported, quality),
      );
      return unsupported;
    }
    if (result.result == null ||
        result.undoToken == null ||
        result.redoToken == null) {
      throw StateError(
        'Backend returned an incomplete surface operation result',
      );
    }
    analytics.commits++;
    analytics.topologyUpdates++;
    analytics.continuityUpdates++;
    final committed = value.copyWith(
      status: SurfaceOperationStatus.committed,
      executionTime: watch.elapsed,
      resultSurface: result.result,
      undoToken: result.undoToken,
      redoToken: result.redoToken,
      diagnostic: result.diagnostic,
      analytics: _snapshot(),
    );
    repository.update(committed, 'committed');
    integration?.onOperationUpdated(
      committed,
      advisor.advise(committed, quality),
    );
    return committed;
  }

  Future<SurfaceOperation> rollback(String id) async {
    final value = _get(id);
    _require(value, const [SurfaceOperationStatus.committed]);
    await kernel.rollbackSurfaceOperation(value.undoToken!);
    analytics.rollbacks++;
    final next = value.copyWith(
      status: SurfaceOperationStatus.rolledBack,
      analytics: _snapshot(),
    );
    repository.update(next, 'rolled-back');
    return next;
  }

  SurfaceOperation cancel(String id) {
    final value = _get(id);
    _require(value, const [
      SurfaceOperationStatus.created,
      SurfaceOperationStatus.previewed,
      SurfaceOperationStatus.validated,
      SurfaceOperationStatus.failed,
      SurfaceOperationStatus.unsupported,
    ]);
    analytics.cancellations++;
    final next = value.copyWith(
      status: SurfaceOperationStatus.cancelled,
      analytics: _snapshot(),
    );
    repository.update(next, 'cancelled');
    return next;
  }

  SurfaceOperation _get(String id) =>
      repository.operations[id] ??
      (throw StateError('Unknown surface operation: $id'));
  void _require(SurfaceOperation value, List<SurfaceOperationStatus> allowed) {
    if (!allowed.contains(value.status)) {
      throw StateError(
        'Invalid surface operation transition: ${value.status.name}',
      );
    }
  }

  SurfaceOperationAnalytics _snapshot() => SurfaceOperationAnalytics(
    executionTime: analytics.totalExecution,
    commits: analytics.commits,
    rollbacks: analytics.rollbacks,
    cancellations: analytics.cancellations,
    validationErrors: analytics.validationErrors,
    topologyUpdates: analytics.topologyUpdates,
    continuityUpdates: analytics.continuityUpdates,
  );
}
