import 'package:flutter/foundation.dart';

import '../../projects/domain/project_manager.dart';
import '../models/pipeline_event.dart';
import '../models/pipeline_progress.dart';
import '../models/reconstruction_job.dart';
import '../models/reconstruction_status.dart';
import '../repositories/reconstruction_repository.dart';
import '../services/isolate_alpha_backend.dart';
import 'reconstruction_backend.dart';
import '../../assistant/domain/smart_assistant_service.dart';

class ReconstructionManager extends ChangeNotifier {
  ReconstructionManager({
    ReconstructionRepository? repository,
    ReconstructionBackend? backend,
    ProjectManager? projects,
  }) : _repository = repository ?? ReconstructionRepository(),
       _backend = backend ?? IsolateAlphaReconstructionBackend(),
       _projects = projects ?? ProjectManager.instance;

  static final ReconstructionManager instance = ReconstructionManager();

  final ReconstructionRepository _repository;
  final ReconstructionBackend _backend;
  final ProjectManager _projects;
  ReconstructionJob? _job;
  bool _backendActive = false;
  Future<void> _saveQueue = Future.value();
  final SmartAssistantService _assistant = SmartAssistantService();
  ReconstructionJob? get job => _job;
  bool get isRunning =>
      _job?.status == ReconstructionStatus.running ||
      _job?.status == ReconstructionStatus.waiting;

  Future<ReconstructionJob?> load(String projectId) async {
    _job = await _repository.loadJob(projectId);
    notifyListeners();
    return _job;
  }

  Future<void> start(String projectId) async {
    if (_backendActive) return;
    final existingLogs = _job?.logs ?? const <PipelineEvent>[];
    _job = ReconstructionJob(
      projectId: projectId,
      status: ReconstructionStatus.waiting,
      startTime: DateTime.now(),
      progress: 0,
      currentStep: 'Preparando',
      logs: existingLogs,
      cancelRequested: false,
    );
    await _persist();
    await _projects.recordReconstructionStarted();
    final context = await _repository.createContext(projectId);
    _job = _job!.copyWith(status: ReconstructionStatus.running);
    await _persist();
    _backendActive = true;
    final result = await _backend.run(
      context,
      onProgress: _onProgress,
      onEvent: _onEvent,
    );
    _backendActive = false;
    if (result.cancelled) {
      _job = _job!.copyWith(
        status: ReconstructionStatus.cancelled,
        endTime: result.endedAt,
        cancelRequested: true,
      );
    } else if (result.success) {
      _job = _job!.copyWith(
        status: ReconstructionStatus.completed,
        endTime: result.endedAt,
        progress: 1,
        currentStep: 'Concluído',
        resultPath: result.resultPath,
      );
      await _projects.recordReconstructionCompleted();
      final project = _projects.current;
      if (project != null) {
        final advice = await _assistant.analyzeReconstruction(
          projectId: project.id,
          qualityScore: project.statistics.qualityScore,
          coverage: project.statistics.coverageScore,
          photosUsed: project.statistics.photoCount,
          photosDiscarded: 0,
        );
        await _projects.recordAIAnalysis(confidence: advice.confidence);
      }
    } else {
      _job = _job!.copyWith(
        status: ReconstructionStatus.failed,
        endTime: result.endedAt,
        error: result.error,
      );
    }
    await _persist();
  }

  Future<void> resume() async {
    final current = _job;
    if (current != null && !_backendActive) await start(current.projectId);
  }

  Future<void> cancel() async {
    if (!_backendActive) return;
    _job = _job!.copyWith(cancelRequested: true);
    await _persist();
    _backend.cancel();
  }

  Future<void> discardInterrupted() async {
    final current = _job;
    if (current == null || !current.canResume || _backendActive) return;
    _job = current.copyWith(
      status: ReconstructionStatus.cancelled,
      endTime: DateTime.now(),
      cancelRequested: true,
    );
    await _persist();
  }

  Future<void> markPaused() async {
    if (!isRunning) return;
    _job = _job!.copyWith(status: ReconstructionStatus.paused);
    await _persist();
  }

  void _onProgress(PipelineProgress progress) {
    _job = _job?.copyWith(
      progress: progress.fraction,
      currentStep: progress.stepName,
    );
    _persist();
    _projects.recordReconstructionProgress(
      progress.fraction,
      progress.stepName,
    );
  }

  void _onEvent(PipelineEvent event) {
    final current = _job;
    if (current == null) return;
    _job = current.copyWith(logs: [...current.logs, event]);
    _persist();
  }

  Future<void> _persist() async {
    final current = _job;
    notifyListeners();
    if (current == null) return;
    _saveQueue = _saveQueue
        .catchError((_) {})
        .then((_) => _repository.saveJob(current));
    await _saveQueue;
  }

  @override
  void dispose() {
    _backend.dispose();
    super.dispose();
  }
}
