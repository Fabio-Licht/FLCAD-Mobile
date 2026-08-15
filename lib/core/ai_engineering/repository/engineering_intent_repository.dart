import 'dart:convert';
import 'dart:io';

import '../analytics/ai_engineering_analytics.dart';
import '../models/ai_engineering_models.dart';

class EngineeringIntentRepository {
  EngineeringIntentRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError.value(
        projectDirectory.path,
        'projectDirectory',
        'Project First persistence requires an absolute project directory',
      );
    }
  }
  final Directory projectDirectory;
  final Map<String, IntentSession> _sessions = {};
  static const root = 'CAD/AIEngineering';
  static const paths = [
    '$root/Sessions',
    '$root/Contexts',
    '$root/Hypotheses',
    '$root/History',
    '$root/Analytics',
    '$root/Recommendations',
    '$root/Audit',
  ];
  List<IntentSession> get sessions => List.unmodifiable(_sessions.values);
  IntentSession? find(String id) => _sessions[id];
  void add(IntentSession session) {
    if (_sessions.containsKey(session.id)) {
      throw StateError('Duplicate AI Engineering session: ${session.id}');
    }
    _sessions[session.id] = session;
  }

  void update(IntentSession session) {
    if (!_sessions.containsKey(session.id)) {
      throw StateError('Unknown AI Engineering session: ${session.id}');
    }
    _sessions[session.id] = session;
  }

  IntentSession rollback(String id, int decisionCount) {
    final current = _sessions[id];
    if (current == null) {
      throw StateError('Unknown AI Engineering session: $id');
    }
    if (decisionCount < 0 || decisionCount > current.history.decisions.length) {
      throw RangeError.range(
        decisionCount,
        0,
        current.history.decisions.length,
        'decisionCount',
      );
    }
    final restored = current.copyWith(
      history: IntentHistory(current.history.decisions.take(decisionCount)),
      state: IntentSessionState.active,
    );
    _sessions[id] = restored;
    return restored;
  }

  String _path(String relative) =>
      '${projectDirectory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(
    String id, {
    required List<AIRecommendation> recommendations,
    required AIEngineeringAnalytics analytics,
  }) async {
    final session = _sessions[id];
    if (session == null) {
      throw StateError('Unknown AI Engineering session: $id');
    }
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    final name = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    Future<void> write(String directory, Object value) => File(
      '${_path(directory)}${Platform.pathSeparator}$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await write('$root/Sessions', session.toJson());
    await write('$root/Contexts', session.context.toJson());
    await write('$root/Hypotheses', session.intent.toJson());
    await write('$root/History', session.history.toJson());
    await write('$root/Analytics', analytics.toJson());
    await write(
      '$root/Recommendations',
      recommendations.map((e) => e.toJson()).toList(),
    );
    await write('$root/Audit', {
      'sessionId': id,
      'projectId': session.context.projectId,
      'candidateScores': {
        for (final candidate in session.intent.candidates)
          candidate.id: candidate.confidence.toJson(),
      },
      'automaticDecisions': false,
      'geometryModified': false,
    });
  }

  Future<IntentSession> load(String id) async {
    final name = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    final file = File(
      '${_path('$root/Sessions')}${Platform.pathSeparator}$name.json',
    );
    if (!await file.exists()) throw StateError('Session not persisted: $id');
    final session = IntentSession.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    _sessions[id] = session;
    return session;
  }
}
