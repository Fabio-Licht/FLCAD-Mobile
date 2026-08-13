import 'dart:io';

import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/projects/domain/project_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late ProjectManager manager;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_manager_');
    manager = ProjectManager(
      repository: ProjectRepository(
        storage: LocalStorageService(rootDirectory: root),
      ),
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('searches by name, client and id instantly', () async {
    final first = await manager.create(name: 'Tampa da Bomba', client: 'MAHA');
    await manager.create(name: 'Suporte Farol', client: 'Bosch');

    manager.search('tampa');
    expect(manager.visibleProjects.single.id, first.id);
    manager.search('bosch');
    expect(manager.visibleProjects.single.client, 'Bosch');
    manager.search(first.id);
    expect(manager.visibleProjects.single.id, first.id);
  });

  test(
    'favorites sort first and archived projects leave the main list',
    () async {
      final first = await manager.create(name: 'Primeiro', client: 'A');
      final favorite = await manager.create(name: 'Favorito', client: 'B');
      await manager.toggleFavorite(favorite);

      expect(manager.visibleProjects.first.id, favorite.id);

      await manager.archive(first);
      expect(
        manager.visibleProjects.any((item) => item.id == first.id),
        isFalse,
      );
      manager.toggleArchived();
      expect(manager.visibleProjects.single.id, first.id);
    },
  );
}
