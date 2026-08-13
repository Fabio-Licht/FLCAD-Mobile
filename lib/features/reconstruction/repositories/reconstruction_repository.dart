import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../projects/data/project_repository.dart';
import '../models/reconstruction_job.dart';
import '../pipeline/pipeline_context.dart';

class ReconstructionRepository {
  ReconstructionRepository({ProjectRepository? projects})
    : _projects = projects ?? ProjectRepository();
  final ProjectRepository _projects;

  static const cacheFolders = [
    'Features',
    'Matches',
    'Sparse',
    'Dense',
    'Mesh',
    'Segmentation',
  ];

  Future<PipelineContext> createContext(String projectId) async {
    final projectDirectory = await _projects.directoryFor(projectId);
    final imagesDirectory = Directory(
      path.join(projectDirectory.path, 'Images'),
    );
    final imagePaths = <String>[];
    if (await imagesDirectory.exists()) {
      await for (final entry in imagesDirectory.list(followLinks: false)) {
        if (entry is File && _isImage(entry.path)) imagePaths.add(entry.path);
      }
    }
    imagePaths.sort();
    final fingerprintParts = <String>[];
    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      final stat = await file.stat();
      fingerprintParts.add(
        '${path.basename(imagePath)}:${stat.size}:${stat.modified.millisecondsSinceEpoch}',
      );
    }
    final reconstruction = Directory(
      path.join(projectDirectory.path, 'Reconstruction'),
    );
    for (final folder in cacheFolders) {
      await Directory(
        path.join(reconstruction.path, 'Cache', folder),
      ).create(recursive: true);
    }
    return PipelineContext(
      projectId: projectId,
      projectPath: projectDirectory.path,
      imagePaths: imagePaths,
      fingerprint: fingerprintParts.join('|'),
    );
  }

  Future<void> saveJob(ReconstructionJob job) async {
    final directory = await _projects.directoryFor(job.projectId);
    final file = File(
      path.join(directory.path, 'Reconstruction', 'reconstruction_job.json'),
    );
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(job.toJson()),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<ReconstructionJob?> loadJob(String projectId) async {
    final directory = await _projects.directoryFor(projectId);
    final file = File(
      path.join(directory.path, 'Reconstruction', 'reconstruction_job.json'),
    );
    if (!await file.exists()) return null;
    try {
      return ReconstructionJob.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isImage(String filePath) => const [
    '.jpg',
    '.jpeg',
    '.png',
    '.heic',
  ].contains(path.extension(filePath).toLowerCase());
}
