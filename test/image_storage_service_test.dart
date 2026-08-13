import 'dart:io';

import 'package:flcad_mobile/core/storage/image_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryDirectory;
  late Directory jobDirectory;
  late File source;
  late ImageStorageService storage;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('flcad_images_');
    jobDirectory = Directory(path.join(temporaryDirectory.path, 'job'));
    await jobDirectory.create();
    source = File(path.join(temporaryDirectory.path, 'camera.jpg'));
    await source.writeAsBytes([1, 2, 3]);
    storage = ImageStorageService();
  });

  tearDown(() => temporaryDirectory.delete(recursive: true));

  test('stores 200 captures sequentially and reloads the gallery', () async {
    for (var index = 0; index < 200; index++) {
      await storage.saveImage(
        sourcePath: source.path,
        projectDirectory: jobDirectory,
      );
    }

    final images = await storage.loadImages(jobDirectory);
    expect(images, hasLength(200));
    expect(path.basename(images.first.path), 'IMG_000001.jpg');
    expect(path.basename(images.last.path), 'IMG_000200.jpg');
  });

  test('deletion removes the file and numbering never overwrites', () async {
    final firstPath = await storage.saveImage(
      sourcePath: source.path,
      projectDirectory: jobDirectory,
    );
    final first = (await storage.loadImages(jobDirectory)).single;
    await storage.deleteImage(first);
    expect(await File(firstPath).exists(), isFalse);

    final secondPath = await storage.saveImage(
      sourcePath: source.path,
      projectDirectory: jobDirectory,
      imageNumber: 1,
    );
    final thirdPath = await storage.saveImage(
      sourcePath: source.path,
      projectDirectory: jobDirectory,
      imageNumber: 1,
    );
    expect(path.basename(secondPath), 'IMG_000001.jpg');
    expect(path.basename(thirdPath), 'IMG_000002.jpg');
  });
}
