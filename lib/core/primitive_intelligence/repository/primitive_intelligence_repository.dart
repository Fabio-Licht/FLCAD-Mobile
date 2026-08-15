import 'dart:convert';
import 'dart:io';

import '../analytics/primitive_intelligence_analytics.dart';
import '../models/primitive_intelligence_models.dart';

class PrimitiveIntelligenceRepository {
  PrimitiveIntelligenceRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError.value(
        projectDirectory.path,
        'projectDirectory',
        'Project First requires an absolute directory',
      );
    }
  }
  final Directory projectDirectory;
  final Map<String, PrimitiveIntelligenceSession> _sessions = {};
  static const paths = [
    'CAD/PrimitiveIntelligence',
    'CAD/PrimitiveEvidence',
    'CAD/PrimitiveRanking',
    'CAD/PrimitiveAnalytics',
    'CAD/PrimitiveSuggestions',
  ];
  PrimitiveIntelligenceSession? find(String id) => _sessions[id];
  void add(PrimitiveIntelligenceSession value) {
    if (_sessions.containsKey(value.id)) {
      throw StateError('Duplicate primitive intelligence session: ${value.id}');
    }
    _sessions[value.id] = value;
  }

  void update(PrimitiveIntelligenceSession value) {
    if (!_sessions.containsKey(value.id)) {
      throw StateError('Unknown primitive intelligence session: ${value.id}');
    }
    _sessions[value.id] = value;
  }

  PrimitiveIntelligenceSession rollback(String id, int decisionCount) {
    final current = _sessions[id];
    if (current == null) {
      throw StateError('Unknown primitive intelligence session: $id');
    }
    if (decisionCount < 0 || decisionCount > current.decisions.length) {
      throw RangeError.range(decisionCount, 0, current.decisions.length);
    }
    final restored = current.copyWith(
      decisions: current.decisions.take(decisionCount),
    );
    _sessions[id] = restored;
    return restored;
  }

  String _path(String relative) =>
      '${projectDirectory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(
    String id, {
    required List<PrimitiveRecommendation> recommendations,
    required PrimitiveIntelligenceAnalytics analytics,
  }) async {
    final session = _sessions[id];
    if (session == null) {
      throw StateError('Unknown primitive intelligence session: $id');
    }
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    final name = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    Future<void> write(String directory, Object value) => File(
      '${_path(directory)}${Platform.pathSeparator}$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await write('CAD/PrimitiveIntelligence', session.toJson());
    await write('CAD/PrimitiveEvidence', {
      for (final h in session.hypotheses)
        h.id: h.evidence.map((e) => e.toJson()).toList(),
    });
    await write(
      'CAD/PrimitiveRanking',
      session.hypotheses
          .map((e) => {'hypothesisId': e.id, 'scores': e.scores.toJson()})
          .toList(),
    );
    await write('CAD/PrimitiveAnalytics', analytics.toJson());
    await write(
      'CAD/PrimitiveSuggestions',
      recommendations.map((e) => e.toJson()).toList(),
    );
  }
}
