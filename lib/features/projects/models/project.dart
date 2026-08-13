import 'project_history.dart';
import 'project_statistics.dart';
import 'project_status.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.client,
    required this.description,
    required this.createdAt,
    required this.status,
    this.isFavorite = false,
    this.history = const ProjectHistory(),
    this.statistics = const ProjectStatistics(),
    this.thumbnailPath,
  });

  final String id;
  final String name;
  final String client;
  final String description;
  final DateTime createdAt;
  final ProjectStatus status;
  final bool isFavorite;
  final ProjectHistory history;
  final ProjectStatistics statistics;
  final String? thumbnailPath;

  bool get isArchived => status == ProjectStatus.archived;
  DateTime get lastModifiedAt => history.lastModifiedAt ?? createdAt;

  Project copyWith({
    String? name,
    String? client,
    String? description,
    ProjectStatus? status,
    bool? isFavorite,
    ProjectHistory? history,
    ProjectStatistics? statistics,
    String? thumbnailPath,
    bool clearThumbnail = false,
  }) => Project(
    id: id,
    name: name ?? this.name,
    client: client ?? this.client,
    description: description ?? this.description,
    createdAt: createdAt,
    status: status ?? this.status,
    isFavorite: isFavorite ?? this.isFavorite,
    history: history ?? this.history,
    statistics: statistics ?? this.statistics,
    thumbnailPath: clearThumbnail ? null : thumbnailPath ?? this.thumbnailPath,
  );
}
