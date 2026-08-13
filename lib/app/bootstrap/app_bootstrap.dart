import '../../core/ai/services/ai_bootstrap.dart';
import '../../features/projects/domain/project_manager.dart';
import '../../features/projects/models/project.dart';
import 'engineering_bootstrap.dart';

class AppBootstrap {
  AppBootstrap._();
  static final instance = AppBootstrap._();
  Future<Project?> initialize() async {
    EngineeringBootstrap.instance.initialize();
    await AIBootstrap.instance.initialize();
    return ProjectManager.instance.initialize();
  }
}
