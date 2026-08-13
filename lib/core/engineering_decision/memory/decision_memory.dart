import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../engineering/learning/engineering_learning.dart';
import '../../storage/local_storage_service.dart';
import '../models/decision_models.dart';

class DecisionMemoryRecord {
  const DecisionMemoryRecord(
    this.decisionId,
    this.status,
    this.reason,
    this.outcome,
    this.timestamp,
    this.actor,
  );
  final String decisionId, reason, outcome, actor;
  final DecisionStatus status;
  final DateTime timestamp;
}

abstract interface class DecisionMemoryStore {
  Future<void> save(String projectId, DecisionMemoryRecord record);
  Future<List<DecisionMemoryRecord>> load(String projectId);
}

class InMemoryDecisionMemoryStore implements DecisionMemoryStore {
  final Map<String, List<DecisionMemoryRecord>> _values = {};
  @override
  Future<void> save(String projectId, DecisionMemoryRecord record) async =>
      _values.putIfAbsent(projectId, () => []).add(record);
  @override
  Future<List<DecisionMemoryRecord>> load(String projectId) async =>
      List.unmodifiable(_values[projectId] ?? const []);
}

class ProjectDecisionMemoryStore implements DecisionMemoryStore {
  ProjectDecisionMemoryStore({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();
  final LocalStorageService _storage;
  final Map<String, Future<void>> _writes = {};
  Future<File> _file(String projectId) async {
    final jobs = await _storage.getJobsDirectory();
    final directory = Directory(path.join(jobs.path, projectId, 'Decisions'));
    await directory.create(recursive: true);
    return File(path.join(directory.path, 'decision-memory.json'));
  }

  @override
  Future<List<DecisionMemoryRecord>> load(String projectId) async {
    final file = await _file(projectId);
    if (!await file.exists()) return const [];
    final values = jsonDecode(await file.readAsString()) as List;
    return values
        .map((raw) {
          final value = (raw as Map).cast<String, dynamic>();
          return DecisionMemoryRecord(
            value['decisionId'] as String,
            DecisionStatus.values.byName(value['status'] as String),
            value['reason'] as String,
            value['outcome'] as String,
            DateTime.parse(value['timestamp'] as String),
            value['actor'] as String,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> save(String projectId, DecisionMemoryRecord record) async {
    final previous = _writes[projectId] ?? Future<void>.value();
    final write = previous.catchError((_) {}).then((_) async {
      final file = await _file(projectId), records = await load(projectId);
      final values = [...records, record]
          .map(
            (value) => {
              'decisionId': value.decisionId,
              'status': value.status.name,
              'reason': value.reason,
              'outcome': value.outcome,
              'timestamp': value.timestamp.toUtc().toIso8601String(),
              'actor': value.actor,
            },
          )
          .toList();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        const JsonEncoder.withIndent(' ').convert(values),
        flush: true,
      );
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    });
    _writes[projectId] = write;
    await write;
    if (identical(_writes[projectId], write)) _writes.remove(projectId);
  }
}

class DecisionMemory {
  DecisionMemory(this.store, {EngineeringLearning? learning})
    : learning = learning ?? EngineeringLearning();
  final DecisionMemoryStore store;
  final EngineeringLearning learning;
  Future<void> record(String projectId, DecisionMemoryRecord record) async {
    await store.save(projectId, record);
    await learning.record(
      EngineeringLearningRecord(
        projectId,
        record.decisionId,
        'engineering-decision',
        record.status.name,
        record.timestamp,
        {
          'reason': record.reason,
          'outcome': record.outcome,
          'actor': record.actor,
        },
      ),
    );
  }
}
