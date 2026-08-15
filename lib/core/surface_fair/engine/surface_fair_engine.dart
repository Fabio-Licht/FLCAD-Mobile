import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../constraints/fair_constraint_solver.dart';
import '../models/surface_fair_models.dart';
import '../repository/surface_fair_repository.dart';
import '../validation/fair_validation.dart';

class SurfaceFairEngine {
  SurfaceFairEngine({required this.operations, required this.repository})
    : validator = const FairValidator(FairConstraintSolver());
  final SurfaceOperationsApi operations;
  final SurfaceFairRepository repository;
  final FairValidator validator;
  int previews = 0,
      validations = 0,
      commits = 0,
      rollbacks = 0,
      reflectionAnalyses = 0,
      zebraAnalyses = 0,
      cancellations = 0;

  SurfaceFairSession begin({
    required FairType type,
    required PatchEntity patch,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<FairFixedRegion> fixedRegions = const [],
    FairContinuity transition = FairContinuity.g2,
  }) {
    if (patch.surface.handle == null) {
      throw StateError('Fair requires a native surface handle');
    }
    if (transition == FairContinuity.g3) {
      throw UnsupportedError(
        'G3 transition infrastructure is reserved but not implemented',
      );
    }
    final value = SurfaceFairSession(
      id: 'surface-fair:${IdGenerator.generate()}',
      type: type,
      patch: patch,
      parameters: Map.unmodifiable(parameters),
      constraints: List.unmodifiable(constraints),
      fixedRegions: List.unmodifiable(fixedRegions),
      transition: transition,
      status: FairStatus.created,
      history: [_event('created')],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    return value;
  }

  SurfaceFairSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [FairStatus.created]);
    final q = quality.patchQualities
        .where((e) => e.patch.id == value.patch.id)
        .firstOrNull;
    final strength = ((value.parameters['fairStrength'] ?? .5) as num)
        .toDouble()
        .clamp(0.0, 1.0);
    final relax = ((value.parameters['relaxLevel'] ?? .5) as num)
        .toDouble()
        .clamp(0.0, 1.0);
    final noise = ((value.parameters['noiseReduction'] ?? 0) as num)
        .toDouble()
        .clamp(0.0, 1.0);
    final baseline = q?.overall ?? .5,
        reflection = q?.reflection.quality ?? baseline,
        zebra = q?.zebra.contrast ?? baseline,
        curvature = q?.curvature.stability ?? baseline;
    final gain = strength * .08 + relax * .05 + noise * .03;
    final prediction = FairPrediction(
      affectedRegions: [value.patch.id, ...value.patch.adjacentPatchIds],
      surfaceEnergy: (1 - relax * .35).clamp(0, 1),
      reflection: (reflection + gain).clamp(0, 1),
      zebra: (zebra + gain).clamp(0, 1),
      curvature: (curvature + gain).clamp(0, 1),
      heatMap: {value.patch.id: strength},
      stress: (strength * .35).clamp(0, 1),
      twist: (strength * .25).clamp(0, 1),
      distortion: (strength * .3).clamp(0, 1),
      quality: (baseline + gain).clamp(0, 1),
      manufacturingScore: (baseline + gain * .8).clamp(0, 1),
    );
    previews++;
    reflectionAnalyses++;
    zebraAnalyses++;
    return _save(
      value.copyWith(
        status: FairStatus.previewed,
        prediction: prediction,
        advice: _advise(value, strength),
        history: [...value.history, _event('previewed')],
      ),
    );
  }

  SurfaceFairSession validate(String id) {
    final value = _get(id);
    _require(value, const [FairStatus.previewed]);
    final result = validator.validate(value);
    validations++;
    return _save(
      value.copyWith(
        status: result.valid ? FairStatus.validated : FairStatus.failed,
        validation: result,
        history: [
          ...value.history,
          _event(result.valid ? 'validated' : 'validation-failed'),
        ],
      ),
    );
  }

  Future<SurfaceFairSession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) async {
    final value = _get(id);
    _require(value, const [FairStatus.validated]);
    var operation = operations.begin(
      type: SurfaceOperationType.fairSurface,
      patch: value.patch,
      parameters: {
        'fairType': value.type.name,
        'transition': value.transition.name,
        'fixedRegions': value.fixedRegions.map((e) => e.toJson()).toList(),
        ...value.parameters,
      },
      constraints: value.constraints,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    if (operation.status != SurfaceOperationStatus.validated) {
      throw StateError('Fair commit prohibited by official validation');
    }
    operation = await operations.commit(
      operation.id,
      projectId: projectId,
      quality: quality,
    );
    if (operation.status == SurfaceOperationStatus.unsupported) {
      return _save(
        value.copyWith(
          status: FairStatus.unsupported,
          operationId: operation.id,
          diagnostic:
              operation.diagnostic ?? 'UnsupportedOperation: fairSurface',
          history: [...value.history, _event('unsupported')],
        ),
      );
    }
    commits++;
    return _save(
      value.copyWith(
        status: FairStatus.committed,
        operationId: operation.id,
        resultSurface: operation.resultSurface,
        diagnostic: operation.diagnostic,
        history: [...value.history, _event('committed')],
      ),
    );
  }

  Future<SurfaceFairSession> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      FairStatus.previewed,
      FairStatus.validated,
      FairStatus.committed,
      FairStatus.unsupported,
    ]);
    if (value.status == FairStatus.committed) {
      await operations.rollback(value.operationId!);
    }
    rollbacks++;
    return _save(
      value.copyWith(
        status: FairStatus.rolledBack,
        history: [...value.history, _event('rolled-back')],
      ),
    );
  }

  SurfaceFairSession cancel(String id) {
    final value = _get(id);
    _require(value, const [
      FairStatus.created,
      FairStatus.previewed,
      FairStatus.validated,
      FairStatus.failed,
      FairStatus.unsupported,
    ]);
    cancellations++;
    return _save(
      value.copyWith(
        status: FairStatus.cancelled,
        history: [...value.history, _event('cancelled')],
      ),
    );
  }

  Map<String, dynamic> get analytics => {
    'operations': repository.sessions.length,
    'previews': previews,
    'validations': validations,
    'reflectionAnalyses': reflectionAnalyses,
    'zebraAnalyses': zebraAnalyses,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'surfaceEnergy': repository.sessions.values
        .map((e) => e.prediction?.surfaceEnergy)
        .whereType<double>()
        .toList(),
    'qualityImprovement': repository.sessions.values
        .map((e) => e.prediction?.quality)
        .whereType<double>()
        .toList(),
    'continuity': repository.sessions.values
        .map((e) => e.transition.name)
        .toList(),
    'modifiedRegions': repository.sessions.values
        .expand((e) => e.prediction?.affectedRegions ?? const <String>[])
        .toSet()
        .length,
  };
  FairAdvice _advise(SurfaceFairSession value, double strength) => FairAdvice(
    strategy: value.type == FairType.smartFair
        ? (value.parameters['noiseReduction'] != null
              ? FairType.noiseReduction
              : FairType.surfaceRelax)
        : value.type,
    strength: strength,
    influenceRadius: ((value.parameters['influenceRadius'] ?? 10) as num)
        .toDouble(),
    recommendations: const [
      'Use the lowest effective intensity',
      'Preserve primary feature and nominal dimension',
      'Minimize distortion',
      'Improve reflection and continuity',
      'Preserve relevant scan detail',
    ],
  );
  SurfaceFairSession _get(String id) =>
      repository.sessions[id] ??
      (throw StateError('Unknown fair session: $id'));
  SurfaceFairSession _save(SurfaceFairSession value) {
    repository.update(value);
    return value;
  }

  void _require(SurfaceFairSession value, List<FairStatus> allowed) {
    if (!allowed.contains(value.status)) {
      throw StateError('Invalid fair transition: ${value.status.name}');
    }
  }

  Map<String, dynamic> _event(String event) => {
    'event': event,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
}
