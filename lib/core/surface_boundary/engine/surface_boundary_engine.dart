import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../constraints/boundary_constraint_solver.dart';
import '../models/surface_boundary_models.dart';
import '../repository/surface_boundary_repository.dart';
import '../validation/boundary_validation.dart';

class SurfaceBoundaryEngine {
  SurfaceBoundaryEngine({required this.operations, required this.repository})
    : validator = const BoundaryValidator(BoundaryConstraintSolver());
  final SurfaceOperationsApi operations;
  final SurfaceBoundaryRepository repository;
  final BoundaryValidator validator;
  int previews = 0,
      validations = 0,
      analyses = 0,
      commits = 0,
      rollbacks = 0,
      cancellations = 0;

  SurfaceBoundarySession begin({
    required BoundaryOperationType type,
    required PatchEntity patch,
    required BoundaryEntity boundary,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<BoundaryFixedRegion> fixedRegions = const [],
    BoundaryContinuity continuity = BoundaryContinuity.g1,
  }) {
    if (patch.surface.handle == null) {
      throw StateError('Boundary editing requires a native surface handle');
    }
    if (!patch.boundaryIds.contains(boundary.id)) {
      throw StateError('Boundary is not part of target patch');
    }
    if (continuity == BoundaryContinuity.g3) {
      throw UnsupportedError(
        'G3 transition infrastructure is reserved but not implemented',
      );
    }
    final value = SurfaceBoundarySession(
      id: 'surface-boundary:${IdGenerator.generate()}',
      type: type,
      patch: patch,
      boundary: boundary,
      parameters: Map.unmodifiable(parameters),
      constraints: List.unmodifiable(constraints),
      fixedRegions: List.unmodifiable(fixedRegions),
      continuity: continuity,
      status: BoundaryEditStatus.created,
      history: [_event('created')],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    return value;
  }

  SurfaceBoundarySession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [BoundaryEditStatus.created]);
    final q = quality.patchQualities
        .where((e) => e.patch.id == value.patch.id)
        .firstOrNull;
    final offset = ((value.parameters['offset'] ?? 0) as num).toDouble(),
        rotation = ((value.parameters['rotation'] ?? 0) as num).toDouble(),
        scale = ((value.parameters['scale'] ?? 1) as num).toDouble();
    final rawDirection = value.parameters['direction'];
    final direction =
        rawDirection is List &&
            rawDirection.length == 3 &&
            rawDirection.every((e) => e is num)
        ? rawDirection.map((e) => (e as num).toDouble()).toList()
        : const <double>[0, 0, 1];
    final magnitude =
        (offset.abs() / (value.boundary.length + offset.abs() + 1) +
                rotation.abs() / 360)
            .clamp(0.0, 1.0);
    final baseline = q?.overall ?? .5;
    final analysis = BoundaryAnalysis(
      originalLength: value.boundary.length,
      predictedLength: (value.boundary.length * scale).abs(),
      continuity: value.continuity,
      curvature: q?.curvature.stability ?? baseline,
      stress: magnitude * .5,
      twist: magnitude * .35,
      quality: (baseline - magnitude * .1).clamp(0, 1),
      manufacturingScore: ((q?.draftScore ?? baseline) - magnitude * .05).clamp(
        0,
        1,
      ),
    );
    final preview = BoundaryPreview(
      newPosition: [for (var i = 0; i < 3; i++) direction[i] * offset],
      reflection: ((q?.reflection.quality ?? baseline) - magnitude * .08).clamp(
        0,
        1,
      ),
      zebra: ((q?.zebra.contrast ?? baseline) - magnitude * .08).clamp(0, 1),
      heatMap: {value.boundary.id: magnitude},
      analysis: analysis,
      affectedRegions: [value.boundary.id, value.patch.id],
    );
    previews++;
    analyses++;
    return _save(
      value.copyWith(
        status: BoundaryEditStatus.previewed,
        preview: preview,
        advice: _advise(value, analysis),
        history: [...value.history, _event('previewed')],
      ),
    );
  }

  SurfaceBoundarySession validate(String id) {
    final value = _get(id);
    _require(value, const [BoundaryEditStatus.previewed]);
    final result = validator.validate(value);
    validations++;
    return _save(
      value.copyWith(
        status: result.valid
            ? BoundaryEditStatus.validated
            : BoundaryEditStatus.failed,
        validation: result,
        history: [
          ...value.history,
          _event(result.valid ? 'validated' : 'validation-failed'),
        ],
      ),
    );
  }

  Future<SurfaceBoundarySession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) async {
    final value = _get(id);
    _require(value, const [BoundaryEditStatus.validated]);
    var operation = operations.begin(
      type: SurfaceOperationType.editBoundary,
      patch: value.patch,
      parameters: {
        'boundaryId': value.boundary.id,
        'boundaryOperation': value.type.name,
        'continuity': value.continuity.name,
        'fixedRegions': value.fixedRegions.map((e) => e.toJson()).toList(),
        'extendIntegration': value.type == BoundaryOperationType.extend
            ? 'ProfessionalExtendSuite'
            : null,
        ...value.parameters,
      },
      constraints: value.constraints,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    if (operation.status != SurfaceOperationStatus.validated) {
      throw StateError('Boundary commit prohibited by official validation');
    }
    operation = await operations.commit(
      operation.id,
      projectId: projectId,
      quality: quality,
    );
    if (operation.status == SurfaceOperationStatus.unsupported) {
      return _save(
        value.copyWith(
          status: BoundaryEditStatus.unsupported,
          operationId: operation.id,
          diagnostic:
              operation.diagnostic ?? 'UnsupportedOperation: editBoundary',
          history: [...value.history, _event('unsupported')],
        ),
      );
    }
    commits++;
    return _save(
      value.copyWith(
        status: BoundaryEditStatus.committed,
        operationId: operation.id,
        resultSurface: operation.resultSurface,
        diagnostic: operation.diagnostic,
        history: [...value.history, _event('committed')],
      ),
    );
  }

  Future<SurfaceBoundarySession> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      BoundaryEditStatus.previewed,
      BoundaryEditStatus.validated,
      BoundaryEditStatus.committed,
      BoundaryEditStatus.unsupported,
    ]);
    if (value.status == BoundaryEditStatus.committed) {
      await operations.rollback(value.operationId!);
    }
    rollbacks++;
    return _save(
      value.copyWith(
        status: BoundaryEditStatus.rolledBack,
        history: [...value.history, _event('rolled-back')],
      ),
    );
  }

  SurfaceBoundarySession cancel(String id) {
    final value = _get(id);
    _require(value, const [
      BoundaryEditStatus.created,
      BoundaryEditStatus.previewed,
      BoundaryEditStatus.validated,
      BoundaryEditStatus.failed,
      BoundaryEditStatus.unsupported,
    ]);
    cancellations++;
    return _save(
      value.copyWith(
        status: BoundaryEditStatus.cancelled,
        history: [...value.history, _event('cancelled')],
      ),
    );
  }

  Map<String, dynamic> get analytics => {
    'operations': repository.sessions.length,
    'previews': previews,
    'validations': validations,
    'boundaryAnalyses': analyses,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'lengthChanges': repository.sessions.values
        .map(
          (e) =>
              (e.preview?.analysis.predictedLength ?? e.boundary.length) -
              e.boundary.length,
        )
        .toList(),
    'continuity': repository.sessions.values
        .map((e) => e.continuity.name)
        .toList(),
    'quality': repository.sessions.values
        .map((e) => e.preview?.analysis.quality)
        .whereType<double>()
        .toList(),
    'affectedRegions': repository.sessions.values
        .expand((e) => e.preview?.affectedRegions ?? const <String>[])
        .toSet()
        .length,
    'strategies': repository.sessions.values.map((e) => e.type.name).toList(),
  };
  BoundaryAdvice _advise(
    SurfaceBoundarySession value,
    BoundaryAnalysis analysis,
  ) => BoundaryAdvice(
    strategy: value.type == BoundaryOperationType.smart
        ? (analysis.twist > .3
              ? BoundaryOperationType.smooth
              : BoundaryOperationType.move)
        : value.type,
    recommendations: const [
      'Preserve continuity',
      'Minimize twist',
      'Prepare boundary for machining',
      'Reduce rework',
      'Retain locked features',
    ],
  );
  SurfaceBoundarySession _get(String id) =>
      repository.sessions[id] ??
      (throw StateError('Unknown boundary session: $id'));
  SurfaceBoundarySession _save(SurfaceBoundarySession value) {
    repository.update(value);
    return value;
  }

  void _require(
    SurfaceBoundarySession value,
    List<BoundaryEditStatus> allowed,
  ) {
    if (!allowed.contains(value.status)) {
      throw StateError('Invalid boundary transition: ${value.status.name}');
    }
  }

  Map<String, dynamic> _event(String event) => {
    'event': event,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
}
