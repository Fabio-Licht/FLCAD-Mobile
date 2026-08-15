import 'dart:convert';
import 'dart:io';

import '../advisor/reference_strategy_advisor.dart';
import '../analytics/smart_reference_analytics.dart';
import '../models/smart_reference_models.dart';

class SmartReferenceRepository {
  SmartReferenceRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError.value(
        projectDirectory.path,
        'projectDirectory',
        'Project First requires an absolute directory',
      );
    }
  }
  final Directory projectDirectory;
  final Map<String, SmartReferenceSession> _sessions = {};
  static const paths = [
    'CAD/SmartReferences',
    'CAD/ReferenceGraphs',
    'CAD/ReferenceStrategies',
    'CAD/AlignmentStrategies',
    'CAD/DatumSuggestions',
    'CAD/CoordinateSystems',
  ];
  SmartReferenceSession? find(String id) => _sessions[id];
  void add(SmartReferenceSession value) {
    if (_sessions.containsKey(value.id)) {
      throw StateError('Duplicate smart reference session: ${value.id}');
    }
    _sessions[value.id] = value;
  }

  void update(SmartReferenceSession value) {
    if (!_sessions.containsKey(value.id)) {
      throw StateError('Unknown smart reference session: ${value.id}');
    }
    _sessions[value.id] = value;
  }

  SmartReferenceSession rollback(String id, int count) {
    final current = _sessions[id];
    if (current == null) {
      throw StateError('Unknown smart reference session: $id');
    }
    if (count < 0 || count > current.decisions.length) {
      throw RangeError.range(count, 0, current.decisions.length);
    }
    final restored = current.copyWith(decisions: current.decisions.take(count));
    _sessions[id] = restored;
    return restored;
  }

  String _path(String relative) =>
      '${projectDirectory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(
    String id, {
    required List<ReferenceRecommendation> recommendations,
    required SmartReferenceAnalytics analytics,
  }) async {
    final session = _sessions[id];
    if (session == null) {
      throw StateError('Unknown smart reference session: $id');
    }
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    final name = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    Future<void> write(String directory, Object value) => File(
      '${_path(directory)}${Platform.pathSeparator}$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await write('CAD/SmartReferences', {
      'session': session.toJson(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'analytics': analytics.toJson(),
    });
    await write('CAD/ReferenceGraphs', session.graph.toJson());
    await write(
      'CAD/ReferenceStrategies',
      recommendations.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/AlignmentStrategies',
      session.strategies.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/DatumSuggestions',
      session.datums.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/CoordinateSystems',
      session.coordinateSystems.map((e) => e.toJson()).toList(),
    );
  }
}
