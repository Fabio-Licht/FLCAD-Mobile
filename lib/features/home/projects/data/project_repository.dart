import '../../../../models/project.dart';

class ProjectRepository {
  ProjectRepository._();

  static final ProjectRepository instance = ProjectRepository._();

  Project? _currentProject;

  Project? get currentProject => _currentProject;

  void save(Project project) {
    _currentProject = project;
  }

  void clear() {
    _currentProject = null;
  }
}