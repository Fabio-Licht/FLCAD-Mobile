import '../models/project.dart';
import '../models/project_history.dart';
import '../models/project_statistics.dart';
import '../models/project_status.dart';

abstract final class ProjectSerializer {
  static Map<String, dynamic> toJson(Project project) => {
    'version': 2,
    'id': project.id,
    'name': project.name,
    'client': project.client,
    'description': project.description,
    'createdAt': project.createdAt.toIso8601String(),
    'status': project.status.name,
    'isFavorite': project.isFavorite,
    'thumbnailPath': project.thumbnailPath,
    'history': {
      'lastOpenedAt': _date(project.history.lastOpenedAt),
      'lastCaptureAt': _date(project.history.lastCaptureAt),
      'lastEditedAt': _date(project.history.lastEditedAt),
      'lastSyncedAt': _date(project.history.lastSyncedAt),
    },
    'statistics': {
      'photoCount': project.statistics.photoCount,
      'reconstructionCount': project.statistics.reconstructionCount,
      'reconstructionProgress': project.statistics.reconstructionProgress,
      'currentReconstructionStep': project.statistics.currentReconstructionStep,
      'qualityScore': project.statistics.qualityScore,
      'coverageScore': project.statistics.coverageScore,
      'scaleScore': project.statistics.scaleScore,
      'aiConfidence': project.statistics.aiConfidence,
    },
  };

  static Project fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['createdAt']) ?? DateTime.now();
    final history = json['history'] as Map<String, dynamic>? ?? const {};
    final statistics = json['statistics'] as Map<String, dynamic>? ?? const {};
    return Project(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Projeto sem nome',
      client: json['client'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: createdAt,
      status: _status(json['status'] as String?),
      isFavorite: json['isFavorite'] as bool? ?? false,
      thumbnailPath: json['thumbnailPath'] as String?,
      history: ProjectHistory(
        lastOpenedAt: _parseDate(history['lastOpenedAt']),
        lastCaptureAt: _parseDate(history['lastCaptureAt']),
        lastEditedAt:
            _parseDate(history['lastEditedAt']) ??
            _parseDate(json['updatedAt']) ??
            createdAt,
        lastSyncedAt: _parseDate(history['lastSyncedAt']),
      ),
      statistics: ProjectStatistics(
        photoCount: statistics['photoCount'] as int? ?? 0,
        reconstructionCount: statistics['reconstructionCount'] as int? ?? 0,
        reconstructionProgress:
            (statistics['reconstructionProgress'] as num? ?? 0).toDouble(),
        currentReconstructionStep:
            statistics['currentReconstructionStep'] as String?,
        qualityScore: (statistics['qualityScore'] as num? ?? 0).toDouble(),
        coverageScore: (statistics['coverageScore'] as num? ?? 0).toDouble(),
        scaleScore: (statistics['scaleScore'] as num? ?? 0).toDouble(),
        aiConfidence: (statistics['aiConfidence'] as num? ?? 0).toDouble(),
      ),
    );
  }

  static ProjectStatus _status(String? value) => switch (value) {
    'capturing' || 'scanning' => ProjectStatus.capturing,
    'processing' ||
    'modeling' ||
    'captureCompleted' => ProjectStatus.processing,
    'reconstructed' ||
    'reconstruction' ||
    'completed' => ProjectStatus.reconstructed,
    'exported' => ProjectStatus.exported,
    'archived' => ProjectStatus.archived,
    _ => ProjectStatus.created,
  };

  static String? _date(DateTime? value) => value?.toIso8601String();
  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
