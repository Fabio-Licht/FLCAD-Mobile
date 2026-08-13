import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../logger/app_logger.dart';

class LocalStorageService {
  LocalStorageService({Directory? rootDirectory})
    : _rootDirectory = rootDirectory;

  final Directory? _rootDirectory;

  Future<Directory> getRootDirectory() async {
    final configuredRoot = _rootDirectory;
    if (configuredRoot != null) {
      await configuredRoot.create(recursive: true);
      return configuredRoot;
    }

    final documents = await getApplicationDocumentsDirectory();

    AppLogger.log('Documents: ${documents.path}', level: LogLevel.debug);

    final root = Directory('${documents.path}/FLCAD');

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    AppLogger.log('Root: ${root.path}', level: LogLevel.debug);

    return root;
  }

  Future<Directory> getJobsDirectory() async {
    final root = await getRootDirectory();

    final jobs = Directory('${root.path}/Jobs');

    if (!await jobs.exists()) {
      await jobs.create(recursive: true);
    }

    return jobs;
  }
}
