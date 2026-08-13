import 'dart:io';

import '../../../core/ai/models/ai_context.dart';
import '../../../core/ai/models/ai_result.dart';
import '../../../core/ai/models/ai_task.dart';
import '../../../core/ai/services/ai_bootstrap.dart';
import '../../projects/data/project_repository.dart';
import 'advisor_engine.dart';

class SmartAssistantService {
  SmartAssistantService({AdvisorEngine? advisors, ProjectRepository? projects})
    : _advisors = advisors ?? AdvisorEngine(ai: AIBootstrap.instance.engine),
      _projects = projects ?? ProjectRepository();
  final AdvisorEngine _advisors;
  final ProjectRepository _projects;

  Future<AIResult> analyzeCapture({
    required String projectId,
    required String imagePath,
    required int photoCount,
  }) async {
    await AIBootstrap.instance.initialize();
    final directory = await _projects.directoryFor(projectId);
    final stat = await FileStat.stat(imagePath);
    return _advisors.capture.analyze(
      AIContext(
        projectId: projectId,
        projectPath: directory.path,
        task: AITask.captureQuality,
        input: {'imagePath': imagePath, 'photoCount': photoCount},
        fingerprint:
            '$imagePath:${stat.size}:${stat.modified.millisecondsSinceEpoch}',
      ),
    );
  }

  Future<AIResult> analyzeCoverage({
    required String projectId,
    required int photoCount,
  }) async {
    await AIBootstrap.instance.initialize();
    final directory = await _projects.directoryFor(projectId);
    return _advisors.coverage.analyze(
      AIContext(
        projectId: projectId,
        projectPath: directory.path,
        task: AITask.coverage,
        input: {'photoCount': photoCount},
        fingerprint: 'coverage:$photoCount',
      ),
    );
  }

  Future<AIResult> analyzeScale({
    required String projectId,
    required String method,
  }) async {
    await AIBootstrap.instance.initialize();
    final directory = await _projects.directoryFor(projectId);
    return _advisors.scale.analyze(
      AIContext(
        projectId: projectId,
        projectPath: directory.path,
        task: AITask.scale,
        input: {'method': method},
        fingerprint: 'scale:$method',
      ),
    );
  }

  Future<AIResult> analyzeReconstruction({
    required String projectId,
    required double qualityScore,
    required double coverage,
    required int photosUsed,
    required int photosDiscarded,
  }) async {
    await AIBootstrap.instance.initialize();
    final directory = await _projects.directoryFor(projectId);
    return _advisors.reconstruction.analyze(
      AIContext(
        projectId: projectId,
        projectPath: directory.path,
        task: AITask.reconstructionAdvice,
        input: {
          'qualityScore': qualityScore,
          'coverage': coverage,
          'photosUsed': photosUsed,
          'photosDiscarded': photosDiscarded,
        },
        fingerprint:
            'reconstruction:$qualityScore:$coverage:$photosUsed:$photosDiscarded',
      ),
    );
  }
}
