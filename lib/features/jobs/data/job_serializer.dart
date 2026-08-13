import '../../../models/job.dart';

class JobSerializer {
  static Map<String, dynamic> toJson(Job job) {
    return {
      'id': job.id,
      'client': job.client,
      'name': job.name,
      'description': job.description,
      'createdAt': job.createdAt.toIso8601String(),
      'status': job.status.name,
    };
  }

  static Job fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? JobStatus.created.name;
    return Job(
      id: json['id'] as String,
      client: json['client'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: JobStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => JobStatus.created,
      ),
    );
  }
}
