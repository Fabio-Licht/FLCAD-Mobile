enum ProjectStatus {
  created,
  scanning,
  processing,
  completed,
}

class Project {
  final String id;
  final String name;
  final String client;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectStatus status;

  const Project({
    required this.id,
    required this.name,
    required this.client,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  Project copyWith({
    String? id,
    String? name,
    String? client,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectStatus? status,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      client: client ?? this.client,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
