import 'dart:convert';
import 'dart:io';

import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/id_generator.dart';
import '../../../models/job.dart';
import 'job_serializer.dart';

class JobRepository {
  JobRepository({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();
  final LocalStorageService _storage;

  static const requiredFolders = [
    'Images',
    'Reconstruction',
    'Mesh',
    'STL',
    'CAD',
    'Reports',
  ];

  Future<Job> createJob({
    required String client,
    required String name,
    String description = '',
  }) async {
    final job = Job(
      id: IdGenerator.generate(),
      client: client,
      name: name,
      createdAt: DateTime.now(),
      description: description,
      status: JobStatus.created,
    );
    await saveJob(job);
    await setActiveJob(job.id);
    return job;
  }

  Future<Directory> ensureJobStructure(String jobId) async {
    final jobsDirectory = await _storage.getJobsDirectory();
    final directory = Directory('${jobsDirectory.path}/$jobId');
    await directory.create(recursive: true);
    for (final folder in requiredFolders) {
      await Directory('${directory.path}/$folder').create(recursive: true);
    }
    return directory;
  }

  Future<Directory> getJobDirectory(String jobId) => ensureJobStructure(jobId);

  Future<void> saveJob(Job job) async {
    final directory = await ensureJobStructure(job.id);
    await File('${directory.path}/job.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(JobSerializer.toJson(job)),
      flush: true,
    );
    AppLogger.log('Job saved: ${job.id}', level: LogLevel.debug);
  }

  Future<Job?> loadJob(String jobId) async {
    final file = File('${(await getJobDirectory(jobId)).path}/job.json');
    if (!await file.exists()) return null;
    try {
      return JobSerializer.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (error, stackTrace) {
      AppLogger.log(
        'Could not load job $jobId',
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> setActiveJob(String jobId) async {
    final root = await _storage.getRootDirectory();
    await File('${root.path}/active_job').writeAsString(jobId, flush: true);
  }

  Future<Job?> loadActiveJob() async {
    final root = await _storage.getRootDirectory();
    final marker = File('${root.path}/active_job');
    if (!await marker.exists()) return null;
    final id = (await marker.readAsString()).trim();
    return id.isEmpty ? null : loadJob(id);
  }
}
