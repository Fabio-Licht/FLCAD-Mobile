import '../../../models/job.dart';
import '../data/job_repository.dart';

class JobManager {
  JobManager({JobRepository? repository})
    : _repository = repository ?? JobRepository();

  static final JobManager instance = JobManager();

  final JobRepository _repository;

  Job? _currentJob;

  Job? get currentJob => _currentJob;

  bool get hasJob => _currentJob != null;

  Future<Job> createJob({
    required String client,
    required String name,
    String description = '',
  }) async {
    final job = await _repository.createJob(
      client: client,
      name: name,
      description: description,
    );

    _currentJob = job;

    return job;
  }

  Future<Job?> restoreActiveJob() async {
    _currentJob = await _repository.loadActiveJob();
    return _currentJob;
  }

  Future<void> updateStatus(JobStatus status) async {
    final job = _currentJob;
    if (job == null) return;
    _currentJob = job.copyWith(status: status);
    await _repository.saveJob(_currentJob!);
  }

  void closeJob() {
    _currentJob = null;
  }
}
