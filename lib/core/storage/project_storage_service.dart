import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/project.dart';

class ProjectStorageService {
  ProjectStorageService._();

  static final ProjectStorageService instance = ProjectStorageService._();

  Future<Directory> createProjectStructure(Project project) async {
    final documents = await getApplicationDocumentsDirectory();

    final root = Directory(
      path.join(documents.path, 'FLCAD', 'Projects', project.id),
    );

    await root.create(recursive: true);

    final folders = ['Sessions', 'Images', 'Mesh', 'CAD', 'Export', 'Logs'];

    for (final folder in folders) {
      await Directory(path.join(root.path, folder)).create(recursive: true);
    }

    return root;
  }
}
