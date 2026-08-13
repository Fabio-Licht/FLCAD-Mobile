import 'package:flcad_mobile/features/jobs/data/job_serializer.dart';
import 'package:flcad_mobile/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('job survives a JSON round trip', () {
    final job = Job(
      id: 'job-1',
      client: 'Cliente',
      name: 'Tampa da Bomba',
      createdAt: DateTime.utc(2026, 8, 13),
      description: 'Captura',
      status: JobStatus.capturing,
    );

    final restored = JobSerializer.fromJson(JobSerializer.toJson(job));

    expect(restored.id, job.id);
    expect(restored.client, job.client);
    expect(restored.name, job.name);
    expect(restored.createdAt, job.createdAt);
    expect(restored.status, JobStatus.capturing);
  });

  test('unknown legacy status safely restores as created', () {
    final restored = JobSerializer.fromJson({
      'id': 'job-1',
      'client': 'Cliente',
      'name': 'Peça',
      'description': '',
      'createdAt': '2026-08-13T00:00:00.000Z',
      'status': 'scanning',
    });

    expect(restored.status, JobStatus.created);
  });
}
