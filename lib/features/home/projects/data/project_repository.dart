import '../../../../models/project.dart';

class ProjectRepository {
  ProjectRepository._();

  static final ProjectRepository instance = ProjectRepository._();

  final List<Project> _projects = [];

  Project? _currentProject;

  Project? get currentProject => _currentProject;

  List<Project> get projects => List.unmodifiable(_projects);

  void create(Project project) {
    _projects.add(project);
    _currentProject = project;
  }

  void open(Project project) {
    _currentProject = project;
  }

  void rename(Project project, String newName) {
    final index = _projects.indexWhere((p) => p.id == project.id);

    if (index == -1) return;

    final updated = project.copyWith(name: newName, updatedAt: DateTime.now());

    _projects[index] = updated;

    if (_currentProject?.id == updated.id) {
      _currentProject = updated;
    }
  }

  void delete(Project project) {
    _projects.removeWhere((p) => p.id == project.id);

    if (_currentProject?.id == project.id) {
      _currentProject = null;
    }
  }

  void clear() {
    _projects.clear();
    _currentProject = null;
  }
}
