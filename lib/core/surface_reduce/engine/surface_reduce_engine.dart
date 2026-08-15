import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../constraints/reduce_constraint_solver.dart';
import '../models/surface_reduce_models.dart';
import '../repository/surface_reduce_repository.dart';
import '../validation/reduce_validation.dart';

class SurfaceReduceEngine {
  SurfaceReduceEngine({required this.operations, required this.repository})
    : validator = const ReduceValidator(ReduceConstraintSolver());
  final SurfaceOperationsApi operations;
  final SurfaceReduceRepository repository;
  final ReduceValidator validator;
  int previews = 0, validations = 0, commits = 0, rollbacks = 0;
  int cancellations = 0;

  SurfaceReduceSession begin({
    required ReduceType type,
    required PatchEntity patch,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<FixedRegion> fixedRegions = const [],
    ReduceContinuity transition = ReduceContinuity.g1,
  }) {
    if (patch.surface.handle == null) {
      throw StateError('Reduce requires a native surface handle');
    }
    if (transition == ReduceContinuity.g3) {
      throw UnsupportedError(
        'G3 transition infrastructure is reserved but not implemented',
      );
    }
    final value = SurfaceReduceSession(
      id: 'surface-reduce:${IdGenerator.generate()}',
      type: type,
      patch: patch,
      parameters: Map.unmodifiable(parameters),
      constraints: List.unmodifiable(constraints),
      fixedRegions: List.unmodifiable(fixedRegions),
      transition: transition,
      status: ReduceStatus.created,
      history: [_event('created')],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    return value;
  }

  SurfaceReduceSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [ReduceStatus.created]);
    final q = quality.patchQualities
        .where((e) => e.patch.id == value.patch.id)
        .firstOrNull;
    final reduction =
        ((value.parameters['reduction'] ?? value.parameters['offset'] ?? 0)
                as num)
            .toDouble()
            .abs();
    final scale = (reduction / (reduction + 100)).clamp(0.0, 1.0);
    final qualityScore = q?.overall ?? .5;
    final direction = _direction(value);
    final prediction = ReducePrediction(
      affectedRegions: [value.patch.id, ...value.patch.adjacentPatchIds],
      stress: scale * .55,
      twist: scale * (direction[2].abs() < .1 ? .6 : .25),
      distortion: scale * .5,
      continuity: value.transition,
      reflection: (qualityScore - scale * .15).clamp(0, 1),
      zebra: ((q?.zebra.contrast ?? qualityScore) - scale * .15).clamp(0, 1),
      heatMap: {value.patch.id: scale},
      quality: (qualityScore - scale * .2).clamp(0, 1),
      manufacturingScore: (1 - scale * .25).clamp(0, 1),
    );
    previews++;
    return _save(
      value.copyWith(
        status: ReduceStatus.previewed,
        prediction: prediction,
        advice: _advise(value, direction, prediction),
        history: [...value.history, _event('previewed')],
      ),
    );
  }

  SurfaceReduceSession validate(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [ReduceStatus.previewed]);
    final result = validator.validate(value, topology, quality);
    validations++;
    return _save(
      value.copyWith(
        status: result.valid ? ReduceStatus.validated : ReduceStatus.failed,
        validation: result,
        history: [
          ...value.history,
          _event(result.valid ? 'validated' : 'validation-failed'),
        ],
      ),
    );
  }

  Future<SurfaceReduceSession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) async {
    final value = _get(id);
    _require(value, const [ReduceStatus.validated]);
    var operation = operations.begin(
      type: SurfaceOperationType.reduceSurface,
      patch: value.patch,
      parameters: {
        'reduceType': value.type.name,
        'transition': value.transition.name,
        'fixedRegions': value.fixedRegions.map((e) => e.toJson()).toList(),
        ...value.parameters,
      },
      constraints: value.constraints,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    if (operation.status != SurfaceOperationStatus.validated) {
      throw StateError('Reduce commit prohibited by official validation');
    }
    operation = await operations.commit(
      operation.id,
      projectId: projectId,
      quality: quality,
    );
    if (operation.status == SurfaceOperationStatus.unsupported) {
      return _save(
        value.copyWith(
          status: ReduceStatus.unsupported,
          operationId: operation.id,
          diagnostic:
              operation.diagnostic ?? 'UnsupportedOperation: reduceSurface',
          history: [...value.history, _event('unsupported')],
        ),
      );
    }
    commits++;
    return _save(
      value.copyWith(
        status: ReduceStatus.committed,
        operationId: operation.id,
        resultSurface: operation.resultSurface,
        diagnostic: operation.diagnostic,
        history: [...value.history, _event('committed')],
      ),
    );
  }

  Future<SurfaceReduceSession> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      ReduceStatus.previewed,
      ReduceStatus.validated,
      ReduceStatus.committed,
      ReduceStatus.unsupported,
    ]);
    if (value.status == ReduceStatus.committed) {
      await operations.rollback(value.operationId!);
    }
    rollbacks++;
    return _save(
      value.copyWith(
        status: ReduceStatus.rolledBack,
        history: [...value.history, _event('rolled-back')],
      ),
    );
  }

  SurfaceReduceSession cancel(String id) {
    final value = _get(id);
    _require(value, const [
      ReduceStatus.created,
      ReduceStatus.previewed,
      ReduceStatus.validated,
      ReduceStatus.failed,
      ReduceStatus.unsupported,
    ]);
    cancellations++;
    return _save(
      value.copyWith(
        status: ReduceStatus.cancelled,
        history: [...value.history, _event('cancelled')],
      ),
    );
  }

  Map<String, dynamic> get analytics => {
    'operations': repository.sessions.length,
    'previews': previews,
    'validations': validations,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'affectedRegions': repository.sessions.values
        .expand((e) => e.prediction?.affectedRegions ?? const <String>[])
        .toSet()
        .length,
    'continuity': repository.sessions.values
        .map((e) => e.transition.name)
        .toList(),
    'quality': repository.sessions.values
        .map((e) => e.prediction?.quality)
        .whereType<double>()
        .toList(),
  };
  List<double> _direction(SurfaceReduceSession value) {
    final raw = value.parameters['direction'];
    if (raw is List && raw.length == 3 && raw.every((e) => e is num)) {
      return raw.map((e) => (e as num).toDouble()).toList();
    }
    return const [0, 0, 1];
  }

  ReduceAdvice _advise(
    SurfaceReduceSession value,
    List<double> direction,
    ReducePrediction prediction,
  ) => ReduceAdvice(
    strategy: value.type == ReduceType.smart
        ? (value.parameters.containsKey('targetRadius')
              ? ReduceType.radius
              : ReduceType.offset)
        : value.type,
    direction: direction,
    recommendations: [
      'Preserve tangency',
      if (value.transition == ReduceContinuity.g2) 'Preserve curvature',
      if (prediction.twist > .3) 'Reduce twist with average normal',
      'Minimize rework',
      if (value.type == ReduceType.manufacturing)
        'Review stamping, machining, electrode, mold and die impact',
    ],
  );
  SurfaceReduceSession _get(String id) =>
      repository.sessions[id] ??
      (throw StateError('Unknown reduce session: $id'));
  SurfaceReduceSession _save(SurfaceReduceSession value) {
    repository.update(value);
    return value;
  }

  void _require(SurfaceReduceSession value, List<ReduceStatus> allowed) {
    if (!allowed.contains(value.status)) {
      throw StateError('Invalid reduce transition: ${value.status.name}');
    }
  }

  Map<String, dynamic> _event(String event) => {
    'event': event,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
}
