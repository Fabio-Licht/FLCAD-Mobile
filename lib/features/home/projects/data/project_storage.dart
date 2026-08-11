import '../../../../models/project.dart';

class ProjectStorage {
  ProjectStorage._();

  static final ProjectStorage instance = ProjectStorage._();

  final List<Project> _storage = [];

  List<Project> loadProjects() {
    return List<Project>.from(_storage);
  }

  void saveProjects(List<Project> projects) {
    _storage
      ..clear()
      ..addAll(projects);
  }

  void clear() {
    _storage.clear();
  }
}