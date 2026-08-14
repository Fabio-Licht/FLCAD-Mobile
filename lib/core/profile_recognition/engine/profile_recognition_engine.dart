import '../../sketch_engine/api/sketch_engine_api.dart';
import '../advisor/profile_advisor.dart';
import '../analytics/profile_analytics.dart';
import '../history/profile_history.dart';
import '../models/profile_models.dart';
import '../recognition/profile_quality.dart';
import '../recognition/profile_recognizer.dart';
import '../repository/profile_repository.dart';
import '../runtime/profile_runtime.dart';
import '../topology/profile_graphs.dart';
import '../validation/profile_validation.dart';

class ProfileRecognitionEngine {
  ProfileRecognitionEngine({
    required this.sketch,
    required this.repository,
    ProfileRecognitionRuntime? runtime,
    ProfileAnalytics? analytics,
    ProfileHistory? history,
    ProfileRecognizer? recognizer,
  }) : runtime = runtime ?? ProfileRecognitionRuntime(),
       analytics = analytics ?? ProfileAnalytics(),
       history = history ?? ProfileHistory(),
       recognizer = recognizer ?? const ProfileRecognizer();
  final SketchEngineApi sketch;
  final ProfileRepository repository;
  final ProfileRecognitionRuntime runtime;
  final ProfileAnalytics analytics;
  final ProfileHistory history;
  final ProfileRecognizer recognizer;
  final graphs = ProfileGraphSet();
  final Map<String, RecognizedProfile> profiles = {};
  final Map<String, ProfileLoop> loops = {};
  final Map<String, SketchRegion> regions = {};
  final List<Map<String, SketchRegion>> _undo = [], _redo = [];
  ProfileValidationResult validation = const ProfileValidationResult([]);
  IntentRecognition intent = const IntentRecognition(
    GeometricIntent.unknown,
    0,
    [],
  );
  ProfileQuality? lastQuality;
  FeatureReadiness? lastReadiness;

  void recognize() {
    final watch = Stopwatch()..start();
    final output = recognizer.recognize(sketch.engine.entities.values);
    profiles
      ..clear()
      ..addEntries(output.profiles.map((p) => MapEntry(p.id, p)));
    loops
      ..clear()
      ..addEntries(output.loops.map((l) => MapEntry(l.id, l)));
    regions
      ..clear()
      ..addEntries(output.regions.map((r) => MapEntry(r.id, r)));
    validation = output.validation;
    intent = output.intent;
    _rebuildGraphs();
    const evaluator = ProfileQualityEvaluator();
    lastQuality = evaluator.evaluate(
      output.profiles,
      output.loops,
      output.regions,
      validation,
    );
    lastReadiness = evaluator.readiness(lastQuality!, output.profiles);
    watch.stop();
    analytics.profiles = profiles.length;
    analytics.loops = loops.length;
    analytics.regions = regions.length;
    analytics.recognitionCount++;
    analytics.totalRecognitionMicros += watch.elapsedMicroseconds;
    analytics.averageComplexity = profiles.isEmpty
        ? 0
        : sketch.engine.entities.length / profiles.length;
    analytics.quality = lastQuality!.score;
    analytics.intentDetections++;
    for (final entry in lastReadiness!.toJson().entries.where(
      (e) => e.value == true,
    )) {
      analytics.readiness.update(entry.key, (v) => v + 1, ifAbsent: () => 1);
    }
    history.record(
      ProfileHistoryAction.recognize,
      sketch.engine.activeSketchId ?? 'sketch',
    );
  }

  void _rebuildGraphs() {
    for (final p in profiles.values) {
      graphs.profiles.add(p.id);
      graphs.topology.add(p.id);
    }
    for (final l in loops.values) {
      graphs.loops.add(l.id);
      graphs.topology.add(l.id);
      graphs.topology.connect(l.profileId, l.id);
    }
    for (final r in regions.values) {
      graphs.regions.add(r.id);
      graphs.topology.add(r.id);
      for (final l in r.loopIds) {
        graphs.topology.connect(l, r.id);
      }
    }
  }

  List<ProfileRecommendation> recommendations() {
    analytics.advisorUsage++;
    return const ProfileAdvisor().advise(
      ProfileRecognitionOutputView(validation, intent),
    );
  }

  SketchRegion merge(String a, String b) {
    final first = regions[a] ?? (throw StateError('Unknown region: $a'));
    final second = regions[b] ?? (throw StateError('Unknown region: $b'));
    _checkpoint();
    final merged = SketchRegion(
      type: RegionType.closed,
      loopIds: {...first.loopIds, ...second.loopIds},
      priority: _max(first.priority, second.priority),
    );
    regions[merged.id] = merged;
    history.record(ProfileHistoryAction.merge, merged.id);
    return merged;
  }

  List<SketchRegion> split(String id) {
    final source = regions[id] ?? (throw StateError('Unknown region: $id'));
    if (source.loopIds.length < 2) {
      throw StateError('Region cannot be split');
    }
    _checkpoint();
    final result = source.loopIds
        .map(
          (l) => SketchRegion(
            type: RegionType.closed,
            loopIds: [l],
            priority: source.priority,
          ),
        )
        .toList();
    for (final r in result) {
      regions[r.id] = r;
    }
    history.record(ProfileHistoryAction.split, id);
    return result;
  }

  void _checkpoint() {
    _undo.add(Map.of(regions));
    _redo.clear();
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(Map.of(regions));
    regions
      ..clear()
      ..addAll(_undo.removeLast());
    history.record(ProfileHistoryAction.undo, 'regions');
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(Map.of(regions));
    regions
      ..clear()
      ..addAll(_redo.removeLast());
    history.record(ProfileHistoryAction.redo, 'regions');
    return true;
  }

  Future<void> persist() => repository.save(
    profiles: profiles.values,
    loops: loops.values,
    regions: regions.values,
    graphs: graphs,
    history: history,
    analytics: analytics,
  );
  int _max(int a, int b) => a > b ? a : b;
}
