import 'dart:io';

import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/jobs/data/job_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'creates the complete job structure and restores the active job',
    () async {
      final root = await Directory.systemTemp.createTemp('flcad_jobs_');
      addTearDown(() => root.delete(recursive: true));
      final repository = JobRepository(
        storage: LocalStorageService(rootDirectory: root),
      );

      final job = await repository.createJob(
        client: 'Cliente',
        name: 'Projeto',
      );
      final directory = await repository.getJobDirectory(job.id);

      expect(
        await File(path.join(directory.path, 'job.json')).exists(),
        isTrue,
      );
      for (final folder in JobRepository.requiredFolders) {
        expect(
          await Directory(path.join(directory.path, folder)).exists(),
          isTrue,
        );
      }
      expect((await repository.loadActiveJob())?.id, job.id);
    },
  );
}
