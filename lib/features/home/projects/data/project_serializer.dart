import '../../../../models/project.dart';

class ProjectSerializer {
  const ProjectSerializer();

  Map<String, dynamic> toJson(Project project) {
    return {
      'version': 1,
      'id': project.id,
      'name': project.name,
      'client': project.client,
      'description': project.description,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'status': project.status.name,
    };
  }

  Project fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      client: json['client'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: ProjectStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }
}
