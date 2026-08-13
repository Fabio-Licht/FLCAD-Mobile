import 'package:flutter/foundation.dart';

import '../data/project_repository.dart';
import '../models/project.dart';
import '../models/project_status.dart';

enum ProjectSort { mostRecent, oldest, client, name }

class ProjectManager extends ChangeNotifier {
  ProjectManager({ProjectRepository? repository})
    : _repository = repository ?? ProjectRepository();

  static final ProjectManager instance = ProjectManager();
  final ProjectRepository _repository;

  final List<Project> _projects = [];
  Project? _current;
  String _query = '';
  ProjectSort _sort = ProjectSort.mostRecent;
  bool _showArchived = false;
  Future<void> _saveQueue = Future.value();

  Project? get current => _current;
  ProjectSort get sort => _sort;
  bool get showArchived => _showArchived;
  List<Project> get projects => List.unmodifiable(_projects);

  List<Project> get visibleProjects {
    final normalized = _query.trim().toLowerCase();
    final result = _projects.where((project) {
      if (project.isArchived != _showArchived) return false;
      if (normalized.isEmpty) return true;
      return project.name.toLowerCase().contains(normalized) ||
          project.client.toLowerCase().contains(normalized) ||
          project.id.toLowerCase().contains(normalized);
    }).toList();
    result.sort(_compare);
    return result;
  }

  int get totalProjects => _projects.length;
  int get totalPhotos =>
      _projects.fold(0, (sum, item) => sum + item.statistics.photoCount);
  int get totalReconstructions => _projects.fold(
    0,
    (sum, item) => sum + item.statistics.reconstructionCount,
  );

  Future<Project?> initialize({bool restoreCurrent = true}) async {
    _projects
      ..clear()
      ..addAll(await _repository.findAll());
    if (restoreCurrent) _current = await _repository.restoreCurrent();
    _replaceCurrentInList();
    notifyListeners();
    return _current;
  }

  Future<Project> create({
    required String name,
    required String client,
    String description = '',
  }) async {
    final project = await _repository.create(
      name: name,
      client: client,
      description: description,
    );
    _projects.add(project);
    _current = project;
    notifyListeners();
    return project;
  }

  Future<Project> open(Project project) async {
    _current = await _repository.open(project);
    _replaceCurrentInList();
    notifyListeners();
    return _current!;
  }

  Future<void> setStatus(ProjectStatus status) =>
      _updateCurrent((project) => project.copyWith(status: status));

  Future<void> recordCapture(String thumbnailPath) => _updateCurrent((project) {
    final now = DateTime.now();
    return project.copyWith(
      status: ProjectStatus.capturing,
      history: project.history.copyWith(lastCaptureAt: now, lastEditedAt: now),
      statistics: project.statistics.copyWith(
        photoCount: project.statistics.photoCount + 1,
      ),
      thumbnailPath: thumbnailPath,
    );
  });

  Future<void> recordImageDeleted({String? thumbnailPath}) => _updateCurrent(
    (project) => project.copyWith(
      history: project.history.copyWith(lastEditedAt: DateTime.now()),
      statistics: project.statistics.copyWith(
        photoCount: (project.statistics.photoCount - 1)
            .clamp(0, 1 << 31)
            .toInt(),
      ),
      thumbnailPath: thumbnailPath,
      clearThumbnail: thumbnailPath == null,
    ),
  );

  Future<void> recordReconstructionStarted() => _updateCurrent(
    (project) => project.copyWith(
      status: ProjectStatus.processing,
      statistics: project.statistics.copyWith(
        reconstructionProgress: 0,
        currentReconstructionStep: 'Preparando',
      ),
    ),
  );

  Future<void> recordReconstructionProgress(double progress, String step) =>
      _updateCurrent(
        (project) => project.copyWith(
          status: ProjectStatus.processing,
          statistics: project.statistics.copyWith(
            reconstructionProgress: progress,
            currentReconstructionStep: step,
          ),
        ),
      );

  Future<void> recordAIAnalysis({
    double? quality,
    double? coverage,
    double? scale,
    double? confidence,
  }) => _updateCurrent(
    (project) => project.copyWith(
      statistics: project.statistics.copyWith(
        qualityScore: quality,
        coverageScore: coverage,
        scaleScore: scale,
        aiConfidence: confidence,
      ),
    ),
  );

  Future<void> recordReconstructionCompleted() => _updateCurrent(
    (project) => project.copyWith(
      status: ProjectStatus.reconstructed,
      history: project.history.copyWith(lastEditedAt: DateTime.now()),
      statistics: project.statistics.copyWith(
        reconstructionCount: project.statistics.reconstructionCount + 1,
        reconstructionProgress: 1,
        currentReconstructionStep: 'Concluído',
      ),
    ),
  );

  Future<void> toggleFavorite(Project project) => _update(
    project.copyWith(
      isFavorite: !project.isFavorite,
      history: project.history.copyWith(lastEditedAt: DateTime.now()),
    ),
  );

  Future<void> archive(Project project) async {
    await _update(
      project.copyWith(
        status: ProjectStatus.archived,
        history: project.history.copyWith(lastEditedAt: DateTime.now()),
      ),
    );
    if (_current?.id == project.id) {
      _current = null;
      await _repository.clearCurrent();
      notifyListeners();
    }
  }

  Future<void> restore(Project project) => _update(
    project.copyWith(
      status: ProjectStatus.created,
      history: project.history.copyWith(lastEditedAt: DateTime.now()),
    ),
  );

  Future<void> delete(Project project) async {
    await _repository.delete(project);
    _projects.removeWhere((item) => item.id == project.id);
    if (_current?.id == project.id) _current = null;
    notifyListeners();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  void changeSort(ProjectSort value) {
    _sort = value;
    notifyListeners();
  }

  void toggleArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }

  Future<void> _updateCurrent(Project Function(Project) transform) async {
    final project = _current;
    if (project == null) return;
    _current = transform(project);
    await _saveProject(_current!);
    _replaceCurrentInList();
    notifyListeners();
  }

  Future<void> _update(Project project) async {
    await _saveProject(project);
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index >= 0) _projects[index] = project;
    if (_current?.id == project.id) _current = project;
    notifyListeners();
  }

  void _replaceCurrentInList() {
    final project = _current;
    if (project == null) return;
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
  }

  Future<void> _saveProject(Project project) {
    _saveQueue = _saveQueue
        .catchError((_) {})
        .then((_) => _repository.save(project));
    return _saveQueue;
  }

  int _compare(Project left, Project right) {
    if (left.isFavorite != right.isFavorite) return left.isFavorite ? -1 : 1;
    return switch (_sort) {
      ProjectSort.mostRecent => right.lastModifiedAt.compareTo(
        left.lastModifiedAt,
      ),
      ProjectSort.oldest => left.createdAt.compareTo(right.createdAt),
      ProjectSort.client => left.client.toLowerCase().compareTo(
        right.client.toLowerCase(),
      ),
      ProjectSort.name => left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      ),
    };
  }
}
