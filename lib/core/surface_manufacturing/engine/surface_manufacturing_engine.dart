import '../../surface_boundary/constraints/boundary_constraint_solver.dart';
import '../../surface_boundary/models/surface_boundary_models.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../constraints/manufacturing_constraint_solver.dart';
import '../models/surface_manufacturing_models.dart';
import '../repository/surface_manufacturing_repository.dart';
import '../validation/manufacturing_validation.dart';

class SurfaceManufacturingEngine {
  SurfaceManufacturingEngine({
    required this.operations,
    required this.repository,
  }) : validator = const ManufacturingValidator(
         ManufacturingConstraintSolver(BoundaryConstraintSolver()),
       );
  final SurfaceOperationsApi operations;
  final SurfaceManufacturingRepository repository;
  final ManufacturingValidator validator;
  int previews = 0,
      draftAnalyses = 0,
      manufacturingAnalyses = 0,
      validations = 0,
      commits = 0,
      rollbacks = 0,
      cancellations = 0;

  SurfaceManufacturingSession begin({
    required ManufacturingOperationType type,
    required PatchEntity patch,
    required ManufacturingIntent intent,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<BoundaryFixedRegion> fixedRegions = const [],
  }) {
    if (patch.surface.handle == null) {
      throw StateError('Manufacturing requires a native surface handle');
    }
    final value = SurfaceManufacturingSession(
      id: 'surface-manufacturing:${IdGenerator.generate()}',
      type: type,
      patch: patch,
      intent: intent,
      parameters: Map.unmodifiable(parameters),
      constraints: List.unmodifiable(constraints),
      fixedRegions: List.unmodifiable(fixedRegions),
      status: ManufacturingStatus.created,
      history: [_event('created')],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    return value;
  }

  SurfaceManufacturingSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [ManufacturingStatus.created]);
    final q = quality.patchQualities
        .where((e) => e.patch.id == value.patch.id)
        .firstOrNull;
    final baseline = q?.overall ?? .5,
        draftScore = q?.draftScore ?? baseline,
        twist = ((value.parameters['twistControl'] ?? .2) as num)
            .toDouble()
            .clamp(0.0, 1.0);
    final negative = q?.draft.negative ?? 0,
        critical = q?.draft.critical ?? 0,
        positive = q?.draft.approved ?? 0;
    final total = (negative + critical + positive).clamp(1, 1 << 30),
        undercut = (negative + critical) / total;
    final analysis = ManufacturingAnalysis(
      negativeRegions: negative,
      neutralRegions: critical,
      positiveRegions: positive,
      draftColorMap: {
        value.patch.id: negative > 0
            ? 'negative'
            : critical > 0
            ? 'neutral'
            : 'positive',
      },
      draftScore: draftScore,
      machiningScore: ((q?.surfaceConfidence ?? baseline) * .6 + baseline * .4)
          .clamp(0, 1),
      stampingScore: (draftScore * .7 + baseline * .3).clamp(0, 1),
      moldScore: (draftScore * .6 + baseline * .4).clamp(0, 1),
      electrodeScore: ((q?.reflectionScore ?? baseline) * .5 + baseline * .5)
          .clamp(0, 1),
      quality: baseline,
      twistRisk: twist * .4,
      undercutRisk: undercut.clamp(0, 1),
    );
    final preview = ManufacturingPreview(
      analysis: analysis,
      affectedRegions: [value.patch.id, ...value.patch.adjacentPatchIds],
      strategyImpact: {
        'quality': analysis.quality,
        'draft': analysis.draftScore,
        'machining': analysis.machiningScore,
      },
    );
    previews++;
    draftAnalyses++;
    manufacturingAnalyses++;
    return _save(
      value.copyWith(
        status: ManufacturingStatus.previewed,
        preview: preview,
        advice: _advise(value, analysis),
        history: [...value.history, _event('previewed')],
      ),
    );
  }

  SurfaceManufacturingSession validate(String id) {
    final value = _get(id);
    _require(value, const [ManufacturingStatus.previewed]);
    final result = validator.validate(value);
    validations++;
    return _save(
      value.copyWith(
        status: result.valid
            ? ManufacturingStatus.validated
            : ManufacturingStatus.failed,
        validation: result,
        history: [
          ...value.history,
          _event(result.valid ? 'validated' : 'validation-failed'),
        ],
      ),
    );
  }

  Future<SurfaceManufacturingSession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) async {
    final value = _get(id);
    _require(value, const [ManufacturingStatus.validated]);
    var operation = operations.begin(
      type: SurfaceOperationType.manufacturingSurface,
      patch: value.patch,
      parameters: {
        'manufacturingOperation': value.type.name,
        'manufacturingIntent': value.intent.toJson(),
        'fixedRegions': value.fixedRegions.map((e) => e.toJson()).toList(),
        'reuse': _reuse(value.type),
        ...value.parameters,
      },
      constraints: value.constraints,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    if (operation.status != SurfaceOperationStatus.validated) {
      throw StateError(
        'Manufacturing commit prohibited by official validation',
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
          status: ManufacturingStatus.unsupported,
          operationId: operation.id,
          diagnostic:
              operation.diagnostic ??
              'UnsupportedOperation: manufacturingSurface',
          history: [...value.history, _event('unsupported')],
        ),
      );
    }
    commits++;
    return _save(
      value.copyWith(
        status: ManufacturingStatus.committed,
        operationId: operation.id,
        resultSurface: operation.resultSurface,
        diagnostic: operation.diagnostic,
        history: [...value.history, _event('committed')],
      ),
    );
  }

  Future<SurfaceManufacturingSession> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      ManufacturingStatus.previewed,
      ManufacturingStatus.validated,
      ManufacturingStatus.committed,
      ManufacturingStatus.unsupported,
    ]);
    if (value.status == ManufacturingStatus.committed) {
      await operations.rollback(value.operationId!);
    }
    rollbacks++;
    return _save(
      value.copyWith(
        status: ManufacturingStatus.rolledBack,
        history: [...value.history, _event('rolled-back')],
      ),
    );
  }

  SurfaceManufacturingSession cancel(String id) {
    final value = _get(id);
    _require(value, const [
      ManufacturingStatus.created,
      ManufacturingStatus.previewed,
      ManufacturingStatus.validated,
      ManufacturingStatus.failed,
      ManufacturingStatus.unsupported,
    ]);
    cancellations++;
    return _save(
      value.copyWith(
        status: ManufacturingStatus.cancelled,
        history: [...value.history, _event('cancelled')],
      ),
    );
  }

  Map<String, dynamic> get analytics => {
    'operations': repository.sessions.length,
    'previews': previews,
    'draftAnalyses': draftAnalyses,
    'manufacturingAnalyses': manufacturingAnalyses,
    'validations': validations,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'strategies': repository.sessions.values.map((e) => e.type.name).toList(),
    'quality': repository.sessions.values
        .map((e) => e.preview?.analysis.quality)
        .whereType<double>()
        .toList(),
    'manufacturingImpact': repository.sessions.values
        .map((e) => e.preview?.strategyImpact)
        .whereType<Map<String, double>>()
        .toList(),
  };
  String _reuse(ManufacturingOperationType type) => switch (type) {
    ManufacturingOperationType.punchExtension ||
    ManufacturingOperationType.dieExtension => 'ProfessionalExtendSuite',
    ManufacturingOperationType.manufacturingOffset => 'ProfessionalReduceSuite',
    ManufacturingOperationType.manufacturingBlend ||
    ManufacturingOperationType.manufacturingTransition => 'SurfaceOperations',
    _ => 'SurfaceContinuityAnalysis',
  };
  ManufacturingAdvice _advise(
    SurfaceManufacturingSession value,
    ManufacturingAnalysis analysis,
  ) => ManufacturingAdvice(
    strategy: value.type == ManufacturingOperationType.smartManufacturing
        ? (analysis.undercutRisk > .3
              ? ManufacturingOperationType.draftSurface
              : ManufacturingOperationType.manufacturingOffset)
        : value.type,
    recommendations: const [
      'Use the lowest viable draft',
      'Minimize extension twist',
      'Reduce undercut risk',
      'Select machining-safe strategy',
      'Prepare manufacturing intent for CAM',
    ],
  );
  SurfaceManufacturingSession _get(String id) =>
      repository.sessions[id] ??
      (throw StateError('Unknown manufacturing session: $id'));
  SurfaceManufacturingSession _save(SurfaceManufacturingSession value) {
    repository.update(value);
    return value;
  }

  void _require(
    SurfaceManufacturingSession value,
    List<ManufacturingStatus> allowed,
  ) {
    if (!allowed.contains(value.status)) {
      throw StateError(
        'Invalid manufacturing transition: ${value.status.name}',
      );
    }
  }

  Map<String, dynamic> _event(String event) => {
    'event': event,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
}
