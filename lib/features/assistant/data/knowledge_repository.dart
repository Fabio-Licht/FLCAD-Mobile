import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../projects/data/project_repository.dart';
import '../models/advisor_recommendation.dart';

class KnowledgeRepository {
  KnowledgeRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;

  Future<void> record(
    String projectId, {
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final directory = await _projects.directoryFor(projectId);
    final file = File(path.join(directory.path, 'AI', 'knowledge.json'));
    final entries = await _readList(file);
    entries.add({
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
    await _write(file, entries);
  }

  Future<void> addRecommendation(AdvisorRecommendation recommendation) async {
    final directory = await _projects.directoryFor(recommendation.projectId);
    final file = File(path.join(directory.path, 'AI', 'advisor.json'));
    final entries = await _readList(file)
      ..add(recommendation.toJson());
    await _write(file, entries);
  }

  Future<List<AdvisorRecommendation>> recommendations(String projectId) async {
    final directory = await _projects.directoryFor(projectId);
    final entries = await _readList(
      File(path.join(directory.path, 'AI', 'advisor.json')),
    );
    return entries.map(AdvisorRecommendation.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _readList(File file) async {
    if (!await file.exists()) return [];
    try {
      return (jsonDecode(await file.readAsString()) as List)
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(File file, List<Map<String, dynamic>> entries) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entries),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }
}
