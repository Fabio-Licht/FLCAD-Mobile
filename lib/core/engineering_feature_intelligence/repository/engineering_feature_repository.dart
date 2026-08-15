import 'dart:convert';
import 'dart:io';

import '../advisor/engineering_feature_advisor.dart';
import '../analytics/engineering_feature_analytics.dart';
import '../models/engineering_feature_models.dart';

class EngineeringFeatureRepository {
  EngineeringFeatureRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError.value(
        projectDirectory.path,
        'projectDirectory',
        'Project First requires an absolute directory',
      );
    }
  }
  final Directory projectDirectory;
  final Map<String, EngineeringFeatureSession> _sessions = {};
  static const paths = [
    'CAD/EngineeringFeatures',
    'CAD/FeatureGraphs',
    'CAD/FeatureTrees',
    'CAD/FeatureRanking',
    'CAD/FeatureAnalytics',
    'CAD/FeatureStrategies',
    'CAD/EngineeringDNA',
  ];
  EngineeringFeatureSession? find(String id) => _sessions[id];
  void add(EngineeringFeatureSession value) {
    if (_sessions.containsKey(value.id)) {
      throw StateError('Duplicate engineering feature session: ${value.id}');
    }
    _sessions[value.id] = value;
  }

  void update(EngineeringFeatureSession value) {
    if (!_sessions.containsKey(value.id)) {
      throw StateError('Unknown engineering feature session: ${value.id}');
    }
    _sessions[value.id] = value;
  }

  EngineeringFeatureSession rollback(String id, int decisionCount) {
    final current = _sessions[id];
    if (current == null) {
      throw StateError('Unknown engineering feature session: $id');
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
    required List<EngineeringFeatureRecommendation> recommendations,
    required EngineeringFeatureAnalytics analytics,
  }) async {
    final session = _sessions[id];
    if (session == null) {
      throw StateError('Unknown engineering feature session: $id');
    }
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    final name = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    Future<void> write(String directory, Object value) => File(
      '${_path(directory)}${Platform.pathSeparator}$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await write('CAD/EngineeringFeatures', {
      'session': session.toJson(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
    });
    await write('CAD/FeatureGraphs', {
      for (final h in session.hypotheses) h.id: h.graph.toJson(),
    });
    await write('CAD/FeatureTrees', {
      for (final h in session.hypotheses) h.id: h.confidenceTree.toJson(),
    });
    await write(
      'CAD/FeatureRanking',
      session.hypotheses
          .map((e) => {'hypothesisId': e.id, 'scores': e.scores.toJson()})
          .toList(),
    );
    await write('CAD/FeatureAnalytics', analytics.toJson());
    await write('CAD/FeatureStrategies', {
      for (final h in session.hypotheses) h.id: h.strategy.toJson(),
    });
    await write('CAD/EngineeringDNA', session.dna.toJson());
  }
}
