import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../advisor/validation_advisor.dart';
import '../analytics/validation_analytics.dart';
import '../graph/validation_graph.dart';
import '../history/validation_history.dart';
import '../history/validation_timeline.dart';
import '../integration/validation_kernel_adapter.dart';
import '../models/validation_models.dart';
import '../preview/heat_map.dart';
import '../repository/validation_repository.dart';
import '../runtime/live_validation_runtime.dart';
import '../validation/live_validation_validation.dart';
import '../validation/validation_quality.dart';

class LiveValidationEngine {
  LiveValidationEngine({
    required this.kernel,
    required this.repository,
    LiveValidationRuntime? runtime,
    ValidationAnalytics? analytics,
    ValidationHistory? history,
    ValidationTimeline? timeline,
  }) : runtime = runtime ?? LiveValidationRuntime(),
       analytics = analytics ?? ValidationAnalytics(),
       history = history ?? ValidationHistory(),
       timeline = timeline ?? ValidationTimeline();
  final GeometryKernelAPI kernel;
  final ValidationRepository repository;
  final LiveValidationRuntime runtime;
  final ValidationAnalytics analytics;
  final ValidationHistory history;
  final ValidationTimeline timeline;
  final graph = ValidationGraph();
  final Map<String, LiveValidationSession> sessions = {};
  final Map<String, HeatMapPreview> heatMaps = {};
  final validator = const LiveValidationValidator();
  LiveValidationSession create(
    ValidationSource source,
    ValidationSource target, {
    ValidationParameters? parameters,
  }) {
    final session = LiveValidationSession(
      source: source,
      target: target,
      parameters: parameters ?? ValidationParameters(),
    );
    sessions[session.id] = session;
    graph.add(session.id);
    analytics.sessions++;
    return session;
  }

  Future<ValidationExecutionResult> start(String id) async {
    final session = _get(id), validation = validator.validate(session);
    if (!validation.valid) {
      session.status = LiveValidationStatus.invalid;
      session.diagnostics
        ..clear()
        ..addAll(validation.issues.map((e) => e.message));
      analytics.failures++;
      return ValidationExecutionResult(
        LiveValidationStatus.invalid,
        diagnostics: session.diagnostics,
      );
    }
    session.status = LiveValidationStatus.running;
    history.record(ValidationHistoryAction.start, id);
    return incrementalUpdate(id, {
      session.target.id,
    }, type: ValidationUpdateType.incremental);
  }

  void pause(String id) {
    _get(id).status = LiveValidationStatus.paused;
    history.record(ValidationHistoryAction.pause, id);
  }

  void resume(String id) {
    _get(id).status = LiveValidationStatus.running;
    history.record(ValidationHistoryAction.resume, id);
  }

  void stop(String id) {
    _get(id).status = LiveValidationStatus.stopped;
    history.record(ValidationHistoryAction.stop, id);
  }

  Future<ValidationExecutionResult> incrementalUpdate(
    String id,
    Set<String> regions, {
    required ValidationUpdateType type,
    String? responsibleFeature,
  }) async {
    final session = _get(id);
    if (session.status == LiveValidationStatus.paused ||
        session.status == LiveValidationStatus.stopped) {
      return ValidationExecutionResult(
        session.status,
        diagnostics: const ['Validation is not running'],
      );
    }
    final previous = Map<String, DeviationSample>.of(session.samples),
        result = await ValidationKernelAdapter(
          kernel,
        ).validate(session, regions);
    session
      ..status = result.status
      ..updatedAt = DateTime.now().toUtc()
      ..responsibleFeature = responsibleFeature;
    session.diagnostics
      ..clear()
      ..addAll(result.diagnostics);
    if (result.success) {
      session.metrics = result.metrics;
      for (final sample in result.samples) {
        if (regions.isEmpty || regions.contains(sample.regionId)) {
          session.samples[sample.regionId] = sample;
        }
      }
      session.affectedRegions
        ..clear()
        ..addAll(regions);
      heatMaps[id] = const HeatMapEngine().create(session);
      analytics.incrementalUpdates++;
      analytics.heatMaps++;
      analytics.successes++;
      analytics.totalQuality += result.metrics!.overallQuality;
      _count(type);
      for (final region in regions) {
        final before = previous[region]?.deviation ?? 0,
            after = session.samples[region]?.deviation ?? before;
        timeline.add(
          ValidationTimelineEntry(
            sessionId: id,
            featureId: responsibleFeature ?? type.name,
            previousError: before,
            currentError: after,
            regionId: region,
            qualityScore: result.metrics!.overallQuality,
          ),
        );
        analytics.timelineUpdates++;
        graph.influence(graph.regionInfluence, region, id);
      }
      history.record(ValidationHistoryAction.update, id);
    } else {
      analytics.failures++;
    }
    return result;
  }

  Future<ValidationExecutionResult> regionUpdate(
    String id,
    Set<String> regions,
  ) => incrementalUpdate(id, regions, type: ValidationUpdateType.region);
  Future<ValidationExecutionResult> featureUpdate(
    String id,
    String feature,
    Set<String> regions,
  ) {
    graph.influence(graph.featureInfluence, feature, id);
    return incrementalUpdate(
      id,
      regions,
      type: ValidationUpdateType.feature,
      responsibleFeature: feature,
    );
  }

  Future<ValidationExecutionResult> referenceUpdate(
    String id,
    String reference,
    Set<String> regions,
  ) {
    graph.influence(graph.referenceInfluence, reference, id);
    return incrementalUpdate(
      id,
      regions,
      type: ValidationUpdateType.datum,
      responsibleFeature: reference,
    );
  }

  Future<ValidationExecutionResult> alignmentUpdate(
    String id,
    String alignment,
    Set<String> regions,
  ) {
    graph.influence(graph.alignmentInfluence, alignment, id);
    return incrementalUpdate(
      id,
      regions,
      type: ValidationUpdateType.alignment,
      responsibleFeature: alignment,
    );
  }

  Future<ValidationExecutionResult> rebuildUpdate(
    String id,
    String feature,
    Set<String> regions,
  ) => incrementalUpdate(
    id,
    regions,
    type: ValidationUpdateType.rebuild,
    responsibleFeature: feature,
  );
  void _count(ValidationUpdateType type) {
    if ({
      ValidationUpdateType.feature,
      ValidationUpdateType.extrude,
      ValidationUpdateType.revolve,
      ValidationUpdateType.sweep,
      ValidationUpdateType.loft,
    }.contains(type)) {
      analytics.featureUpdates++;
    }
    if (type == ValidationUpdateType.datum ||
        type == ValidationUpdateType.reference) {
      analytics.datumUpdates++;
    }
    if (type == ValidationUpdateType.alignment) analytics.alignmentUpdates++;
  }

  ValidationSnapshot snapshot(String id) {
    final value = history.snapshot(_get(id));
    analytics.snapshots++;
    return value;
  }

  void createBaseline(String id, String snapshotId) =>
      history.baseline(id, snapshotId);
  void rollback(String id, String snapshotId) {
    final session = _get(id),
        snapshot =
            history.snapshots[snapshotId] ??
            (throw StateError('Unknown snapshot: $snapshotId'));
    session.metrics = snapshot.metrics;
    session.samples
      ..clear()
      ..addEntries(snapshot.samples.map((e) => MapEntry(e.regionId, e)));
    session.updatedAt = DateTime.now().toUtc();
    heatMaps[id] = const HeatMapEngine().create(session);
    analytics.rollbacks++;
    history.record(
      ValidationHistoryAction.rollback,
      id,
      snapshotId: snapshotId,
    );
  }

  void restoreBaseline(String id) {
    final baseline =
        history.baselines[id] ?? (throw StateError('No baseline: $id'));
    rollback(id, baseline.id);
  }

  ValidationSnapshot replay(String snapshotId) =>
      history.snapshots[snapshotId] ??
      (throw StateError('Unknown snapshot: $snapshotId'));
  Map<String, double> compareSnapshots(String a, String b) {
    final first = replay(a).metrics, second = replay(b).metrics;
    return {
      'rms': second.rms - first.rms,
      'maximumDeviation': second.maximumDeviation - first.maximumDeviation,
      'quality': second.overallQuality - first.overallQuality,
    };
  }

  void addDependency(String id, String parent) => graph.connect(parent, id);
  LiveValidationValidationResult validate(String id) =>
      validator.validate(_get(id));
  HeatMapPreview heatMap(String id) =>
      heatMaps[id] ?? (throw StateError('Heat map unavailable: $id'));
  ValidationQuality quality(String id) =>
      const ValidationQualityEngine().evaluate(_get(id));
  List<ValidationRecommendation> recommendations(String id) {
    analytics.advisorUpdates++;
    return const ValidationAdvisor().analyze(_get(id), heatMap(id));
  }

  LiveValidationSession _get(String id) =>
      sessions[id] ?? (throw StateError('Unknown validation: $id'));
  Future<void> persist() => repository.save(
    sessions: sessions.values,
    history: history,
    timeline: timeline,
    analytics: analytics,
    heatMaps: heatMaps.values,
  );
}
