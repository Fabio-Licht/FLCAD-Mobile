import 'dart:convert';
import 'dart:io';

import '../advisor/reconstruction_advisor.dart';
import '../analytics/reconstruction_strategy_analytics.dart';
import '../models/reconstruction_strategy_models.dart';

class ReconstructionStrategyRepository {
  ReconstructionStrategyRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError.value(
        projectDirectory.path,
        'projectDirectory',
        'Project First requires an absolute directory',
      );
    }
  }
  final Directory projectDirectory;
  final Map<String, ReconstructionStrategySession> _sessions = {};
  final Map<String, List<ReconstructionStrategySession>> _versions = {};
  static const paths = [
    'CAD/ReconstructionStrategies',
    'CAD/EngineeringPlaybooks',
    'CAD/StrategyGraphs',
    'CAD/DependencyGraphs',
    'CAD/DifficultyAnalysis',
    'CAD/StrategyAnalytics',
  ];
  ReconstructionStrategySession? find(String id) => _sessions[id];
  void add(ReconstructionStrategySession value) {
    if (_sessions.containsKey(value.id)) {
      throw StateError(
        'Duplicate reconstruction strategy session: ${value.id}',
      );
    }
    _sessions[value.id] = value;
    _versions[value.id] = [value];
  }

  void update(ReconstructionStrategySession value) {
    if (!_sessions.containsKey(value.id)) {
      throw StateError('Unknown reconstruction strategy session: ${value.id}');
    }
    _sessions[value.id] = value;
    _versions[value.id]!.add(value);
  }

  ReconstructionStrategySession rollback(String id, int decisionCount) {
    final versions = _versions[id];
    if (versions == null) {
      throw StateError('Unknown reconstruction strategy session: $id');
    }
    final matches = versions
        .where((e) => e.decisions.length == decisionCount)
        .toList();
    if (matches.isEmpty) {
      throw RangeError(
        'No reconstruction strategy version for decision count $decisionCount',
      );
    }
    final restored = matches.first;
    _sessions[id] = restored;
    _versions[id]!.add(restored);
    return restored;
  }

  String _path(String relative) =>
      '${projectDirectory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(
    String id, {
    required List<ReconstructionRecommendation> recommendations,
    required ReconstructionStrategyAnalytics analytics,
  }) async {
    final session = _sessions[id];
    if (session == null) {
      throw StateError('Unknown reconstruction strategy session: $id');
    }
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    final name = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    Future<void> write(String directory, Object value) => File(
      '${_path(directory)}${Platform.pathSeparator}$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await write('CAD/ReconstructionStrategies', {
      'session': session.toJson(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
    });
    await write('CAD/EngineeringPlaybooks', session.playbook.toJson());
    await write('CAD/StrategyGraphs', {
      for (final strategy in session.strategies) strategy.id: strategy.toJson(),
    });
    await write('CAD/DependencyGraphs', {
      for (final strategy in session.strategies)
        strategy.id: strategy.graph.toJson(),
    });
    await write('CAD/DifficultyAnalysis', session.difficulty.toJson());
    await write('CAD/StrategyAnalytics', analytics.toJson());
  }
}
