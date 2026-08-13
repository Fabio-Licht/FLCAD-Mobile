import 'project.dart';
import 'project_status.dart';

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.client,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.photoCount,
    required this.status,
    required this.isFavorite,
    required this.reconstructionProgress,
    this.currentReconstructionStep,
    this.thumbnailPath,
  });

  factory ProjectSummary.fromProject(Project project) => ProjectSummary(
    id: project.id,
    name: project.name,
    client: project.client,
    createdAt: project.createdAt,
    lastModifiedAt: project.lastModifiedAt,
    photoCount: project.statistics.photoCount,
    status: project.status,
    isFavorite: project.isFavorite,
    reconstructionProgress: project.statistics.reconstructionProgress,
    currentReconstructionStep: project.statistics.currentReconstructionStep,
    thumbnailPath: project.thumbnailPath,
  );

  final String id;
  final String name;
  final String client;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final int photoCount;
  final ProjectStatus status;
  final bool isFavorite;
  final double reconstructionProgress;
  final String? currentReconstructionStep;
  final String? thumbnailPath;
}
