import 'dart:io';

import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/reconstruction/models/reconstruction_job.dart';
import 'package:flcad_mobile/features/reconstruction/models/reconstruction_status.dart';
import 'package:flcad_mobile/features/reconstruction/repositories/reconstruction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'persists interrupted jobs and prepares all cache directories',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'flcad_reconstruction_',
      );
      addTearDown(() => root.delete(recursive: true));
      final projects = ProjectRepository(
        storage: LocalStorageService(rootDirectory: root),
      );
      final project = await projects.create(name: 'Tampa', client: 'MAHA');
      final repository = ReconstructionRepository(projects: projects);
      final context = await repository.createContext(project.id);
      final job = ReconstructionJob(
        projectId: project.id,
        status: ReconstructionStatus.running,
        progress: .35,
        currentStep: 'Dense Cloud',
        logs: const [],
        cancelRequested: false,
      );
      await repository.saveJob(job);

      final restored = await repository.loadJob(project.id);
      expect(restored?.canResume, isTrue);
      expect(restored?.progress, .35);
      for (final folder in ReconstructionRepository.cacheFolders) {
        expect(
          await Directory('${context.cachePath}/$folder').exists(),
          isTrue,
        );
      }
    },
  );
}
