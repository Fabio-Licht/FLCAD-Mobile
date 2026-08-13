import 'dart:io';

import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory root;
  late ProjectRepository repository;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_projects_');
    repository = ProjectRepository(
      storage: LocalStorageService(rootDirectory: root),
    );
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'creates, opens and restores a project with its complete workspace',
    () async {
      final created = await repository.create(name: 'Tampa', client: 'MAHA');
      final directory = await repository.directoryFor(created.id);

      for (final folder in ProjectRepository.requiredFolders) {
        expect(
          await Directory(path.join(directory.path, folder)).exists(),
          isTrue,
        );
      }
      expect(
        await File(path.join(directory.path, 'job.json')).exists(),
        isTrue,
      );
      expect((await repository.restoreCurrent())?.id, created.id);
    },
  );

  test('deleting a project removes its complete workspace', () async {
    final project = await repository.create(name: 'Suporte', client: 'Bosch');
    final directory = await repository.directoryFor(project.id);
    await File(
      path.join(directory.path, 'Images', 'IMG_000001.jpg'),
    ).writeAsBytes([1]);

    await repository.delete(project);

    expect(await directory.exists(), isFalse);
    expect(await repository.restoreCurrent(), isNull);
  });
}
