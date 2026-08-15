import 'dart:convert';
import 'dart:io';

import '../analytics/interactive_assistant_analytics.dart';
import '../models/interactive_assistant_models.dart';

class InteractiveAssistantRepository {
  InteractiveAssistantRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError.value(
        projectDirectory.path,
        'projectDirectory',
        'Project First requires an absolute directory',
      );
    }
  }
  final Directory projectDirectory;
  final Map<String, InteractiveAssistantSession> _sessions = {};
  final Map<String, List<InteractiveAssistantSession>> _versions = {};
  static const paths = [
    'CAD/InteractiveAssistant',
    'CAD/EngineeringTimeline',
    'CAD/SessionSnapshots',
    'CAD/EngineeringAlerts',
    'CAD/EngineeringSuggestions',
    'CAD/EngineeringContext',
  ];
  InteractiveAssistantSession? find(String id) => _sessions[id];
  void add(InteractiveAssistantSession session) {
    if (_sessions.containsKey(session.id)) {
      throw StateError(
        'Duplicate interactive assistant session: ${session.id}',
      );
    }
    _sessions[session.id] = session;
    _versions[session.id] = [session];
  }

  void update(InteractiveAssistantSession session) {
    if (!_sessions.containsKey(session.id)) {
      throw StateError('Unknown interactive assistant session: ${session.id}');
    }
    _sessions[session.id] = session;
    _versions[session.id]!.add(session);
  }

  InteractiveAssistantSession rollback(String id, int snapshotSequence) {
    final versions = _versions[id];
    if (versions == null) {
      throw StateError('Unknown interactive assistant session: $id');
    }
    final matches = versions
        .where((e) => e.snapshots.any((s) => s.sequence == snapshotSequence))
        .toList();
    if (matches.isEmpty) {
      throw RangeError('Unknown snapshot sequence: $snapshotSequence');
    }
    final restored = matches.first;
    _sessions[id] = restored;
    _versions[id]!.add(restored);
    return restored;
  }

  String _path(String relative) =>
      '${projectDirectory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(
    String id,
    InteractiveAssistantAnalytics analytics,
  ) async {
    final session = _sessions[id];
    if (session == null) {
      throw StateError('Unknown interactive assistant session: $id');
    }
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    final name = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    Future<void> write(String directory, Object value) => File(
      '${_path(directory)}${Platform.pathSeparator}$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await write('CAD/InteractiveAssistant', {
      'session': session.toJson(),
      'analytics': analytics.toJson(),
    });
    await write(
      'CAD/EngineeringTimeline',
      session.timeline.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/SessionSnapshots',
      session.snapshots.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/EngineeringAlerts',
      session.alerts.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/EngineeringSuggestions',
      session.suggestions.map((e) => e.toJson()).toList(),
    );
    await write('CAD/EngineeringContext', session.context.toJson());
  }
}
