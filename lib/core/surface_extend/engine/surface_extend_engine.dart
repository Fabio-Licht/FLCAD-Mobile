import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_morph/api/surface_morph_api.dart';
import '../../surface_morph/models/surface_morph_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../../utils/id_generator.dart';
import '../analyzer/extend_analyzer.dart';
import '../integration/surface_extend_integration.dart';
import '../models/surface_extend_models.dart';
import '../repository/surface_extend_repository.dart';

class SurfaceExtendEngine {
  SurfaceExtendEngine({
    required this.morph,
    required this.repository,
    this.integration,
  });
  final SurfaceMorphApi morph;
  final SurfaceExtendRepository repository;
  final SurfaceExtendIntegration? integration;
  final analyzer = const ExtendAnalyzer();
  int previews = 0, commits = 0, rollbacks = 0, cancellations = 0;
  Duration totalTime = Duration.zero;
  ExtendSession begin({
    required ExtendType type,
    required PatchEntity patch,
    required String boundaryId,
    required List<MorphAnchor> anchors,
    Map<String, dynamic> parameters = const {},
    String manufacturingIntent = '',
  }) {
    if (!patch.boundaryIds.contains(boundaryId)) {
      throw StateError('Boundary is not part of target patch');
    }
    final value = ExtendSession(
      id: 'surface-extend:${IdGenerator.generate()}',
      type: type,
      patch: patch,
      boundaryId: boundaryId,
      anchors: List.unmodifiable(anchors),
      parameters: Map.unmodifiable(parameters),
      manufacturingIntent: manufacturingIntent,
      status: ExtendStatus.created,
      history: [_event('created')],
      createdAt: DateTime.now().toUtc(),
    );
    repository.add(value);
    return value;
  }

  ExtendSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [ExtendStatus.created]);
    final watch = Stopwatch()..start(),
        analysis = analyzer.analyze(value, quality);
    watch.stop();
    totalTime += watch.elapsed;
    previews++;
    return _save(
      value.copyWith(
        status: ExtendStatus.previewed,
        analysis: analysis,
        history: [...value.history, _event('previewed')],
      ),
    );
  }

  ExtendSession validate(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final value = _get(id);
    _require(value, const [ExtendStatus.previewed]);
    final a = value.analysis!,
        top = value.patch.health == TopologyHealth.healthy,
        continuity = a.predictedContinuity.isNotEmpty,
        reflection = a.reflectionScore.isFinite && a.reflectionScore >= 0,
        zebra = a.zebraScore.isFinite && a.zebraScore >= 0,
        draft =
            value.type != ExtendType.draft ||
            value.parameters['draftDirection'] != null,
        qualityOk = a.estimatedQuality >= .4,
        twist = a.twistRisk < .8,
        intersection = a.selfIntersectionRisk < .6,
        constraints = value.anchors.isNotEmpty,
        errors = <String>[
          if (!top) 'Topology failed',
          if (!continuity) 'Continuity failed',
          if (!reflection) 'Reflection failed',
          if (!zebra) 'Zebra failed',
          if (!draft) 'Draft direction missing',
          if (!qualityOk) 'Quality failed',
          if (!twist) 'Twist risk too high',
          if (!intersection) 'Self-intersection risk too high',
          if (!constraints) 'Anchors missing',
        ];
    final validation = ExtendValidation(
      errors.isEmpty,
      top,
      continuity,
      reflection,
      zebra,
      draft,
      qualityOk,
      twist,
      intersection,
      constraints,
      errors,
    );
    return _save(
      value.copyWith(
        status: validation.valid ? ExtendStatus.validated : ExtendStatus.failed,
        validation: validation,
        history: [
          ...value.history,
          _event(validation.valid ? 'validated' : 'validation-failed'),
        ],
      ),
    );
  }

  Future<ExtendSession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) async {
    final value = _get(id);
    _require(value, const [ExtendStatus.validated]);
    if (value.validation?.valid != true) {
      throw StateError('Extend commit prohibited');
    }
    var m = morph.begin(
      tool: value.type == ExtendType.curvatureG2
          ? MorphTool.match
          : MorphTool.pull,
      patch: value.patch,
      anchors: value.anchors,
      radius: ((value.parameters['distance'] as num?)?.toDouble() ?? 1)
          .abs()
          .clamp(.001, double.infinity),
      falloff: value.type == ExtendType.curvatureG2
          ? FalloffType.gaussian
          : FalloffType.smooth,
      parameters: {'extendType': value.type.name, ...value.parameters},
    );
    m = morph.preview(m.id, topology, quality);
    m = morph.validate(m.id, topology, quality);
    m = await morph.commit(
      m.id,
      topology: topology,
      quality: quality,
      projectId: projectId,
    );
    if (m.status == MorphStatus.unsupported) {
      return _save(
        value.copyWith(
          status: ExtendStatus.unsupported,
          morphSessionId: m.id,
          diagnostic: m.diagnostic,
          history: [...value.history, _event('unsupported')],
        ),
      );
    }
    commits++;
    return _save(
      value.copyWith(
        status: ExtendStatus.committed,
        morphSessionId: m.id,
        diagnostic: m.diagnostic,
        history: [...value.history, _event('committed')],
      ),
    );
  }

  Future<ExtendSession> rollback(String id) async {
    final value = _get(id);
    _require(value, const [
      ExtendStatus.previewed,
      ExtendStatus.validated,
      ExtendStatus.committed,
    ]);
    if (value.status == ExtendStatus.committed) {
      await morph.rollback(value.morphSessionId!);
    }
    rollbacks++;
    return _save(
      value.copyWith(
        status: ExtendStatus.rolledBack,
        history: [...value.history, _event('rolled-back')],
      ),
    );
  }

  ExtendSession cancel(String id) {
    final value = _get(id);
    _require(value, const [
      ExtendStatus.created,
      ExtendStatus.previewed,
      ExtendStatus.validated,
      ExtendStatus.failed,
      ExtendStatus.unsupported,
    ]);
    cancellations++;
    return _save(
      value.copyWith(
        status: ExtendStatus.cancelled,
        history: [...value.history, _event('cancelled')],
      ),
    );
  }

  ExtendSession smart(ExtendSession value) {
    final suggested = analyzer.suggest(value);
    return ExtendSession(
      id: value.id,
      type: suggested,
      patch: value.patch,
      boundaryId: value.boundaryId,
      anchors: value.anchors,
      parameters: value.parameters,
      manufacturingIntent: value.manufacturingIntent,
      status: value.status,
      history: value.history,
      createdAt: value.createdAt,
    );
  }

  Map<String, dynamic> get analytics => {
    'operations': repository.sessions.length,
    'previews': previews,
    'commits': commits,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'averageMicros': previews == 0 ? 0 : totalTime.inMicroseconds ~/ previews,
    'averageDistance': _average('distance'),
    'averageAngle': _average('angle'),
    'twistIncidence': repository.sessions.values
        .where((e) => (e.analysis?.twistRisk ?? 0) >= .5)
        .length,
  };
  double _average(String key) {
    final values = repository.sessions.values
        .map((e) => (e.parameters[key] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  }

  ExtendSession _get(String id) =>
      repository.sessions[id] ??
      (throw StateError('Unknown extend session: $id'));
  ExtendSession _save(ExtendSession value) {
    repository.update(value);
    integration?.onExtendUpdated(value, analytics);
    return value;
  }

  void _require(ExtendSession v, List<ExtendStatus> s) {
    if (!s.contains(v.status)) {
      throw StateError('Invalid extend transition: ${v.status.name}');
    }
  }

  Map<String, dynamic> _event(String e) => {
    'event': e,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
}
