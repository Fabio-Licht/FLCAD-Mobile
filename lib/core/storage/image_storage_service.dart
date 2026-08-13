import 'dart:io';

import 'package:path/path.dart' as path;

import '../../models/captured_image.dart';
import '../logger/app_logger.dart';

class ImageStorageService {
  ImageStorageService();
  static final ImageStorageService instance = ImageStorageService();

  Future<String> saveImage({
    required String sourcePath,
    required Directory projectDirectory,
    int? imageNumber,
  }) async {
    final imagesDirectory = await _imagesDirectory(projectDirectory);
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Imagem temporária não encontrada', sourcePath);
    }
    var number = imageNumber ?? await nextImageNumber(projectDirectory);
    while (true) {
      final destination = path.join(
        imagesDirectory.path,
        'IMG_${number.toString().padLeft(6, '0')}.jpg',
      );
      final destinationFile = File(destination);
      RandomAccessFile? output;
      var reserved = false;
      try {
        await destinationFile.create(exclusive: true);
        reserved = true;
        output = await destinationFile.open(mode: FileMode.writeOnly);
        await for (final bytes in sourceFile.openRead()) {
          await output.writeFrom(bytes);
        }
        await output.flush();
        await output.close();
        AppLogger.log('Image stored: $destination', level: LogLevel.debug);
        return destination;
      } on FileSystemException {
        if (!reserved && await destinationFile.exists()) {
          number++;
          continue;
        }
        await output?.close();
        if (await destinationFile.exists()) await destinationFile.delete();
        rethrow;
      }
    }
  }

  Future<List<CapturedImage>> loadImages(Directory projectDirectory) async {
    final directory = await _imagesDirectory(projectDirectory);
    final files = await directory
        .list()
        .where((entry) => entry is File && _imageNumber(entry.path) != null)
        .cast<File>()
        .toList();
    files.sort(
      (a, b) => _imageNumber(a.path)!.compareTo(_imageNumber(b.path)!),
    );
    return Future.wait(
      files.map((file) async {
        final stat = await file.stat();
        return CapturedImage(
          id: path.basenameWithoutExtension(file.path),
          path: file.path,
          capturedAt: stat.modified,
        );
      }),
    );
  }

  Future<int> nextImageNumber(Directory projectDirectory) async {
    final directory = await _imagesDirectory(projectDirectory);
    var highest = 0;
    await for (final entry in directory.list()) {
      final number = _imageNumber(entry.path);
      if (entry is File && number != null && number > highest) highest = number;
    }
    return highest + 1;
  }

  Future<void> deleteImage(CapturedImage image) async {
    final file = File(image.path);
    if (await file.exists()) await file.delete();
  }

  Future<Directory> _imagesDirectory(Directory projectDirectory) async {
    final directory = Directory(path.join(projectDirectory.path, 'Images'));
    await directory.create(recursive: true);
    return directory;
  }

  int? _imageNumber(String filePath) {
    final match = RegExp(
      r'^IMG_(\d{6})\.(?:jpe?g)$',
      caseSensitive: false,
    ).firstMatch(path.basename(filePath));
    return match == null ? null : int.parse(match.group(1)!);
  }
}
