import 'dart:convert';
import 'dart:io';
import '../analytics/alignment_analytics.dart';
import '../history/alignment_history.dart';
import '../models/alignment_models.dart';
import '../preview/alignment_preview.dart';

class AlignmentRepository {
  AlignmentRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Alignments',
    'CAD/AlignmentHistory',
    'CAD/AlignmentAnalytics',
    'CAD/AlignmentPreview',
    'CAD/BestFit',
    'CAD/CoordinateMappings',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<Alignment> alignments,
    required AlignmentHistory history,
    required AlignmentAnalytics analytics,
    required Iterable<AlignmentPreview> previews,
    required Map<String, Map<String, String>> mappings,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final a in alignments) {
      final folder =
          {
            AlignmentType.bestFit,
            AlignmentType.localBestFit,
            AlignmentType.regionBestFit,
          }.contains(a.type)
          ? paths[4]
          : paths[0];
      await File(
        '${_dir(folder).path}${Platform.pathSeparator}${_safe(a.id)}.json',
      ).writeAsString(jsonEncode(a.toJson()));
    }
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    for (final p in previews) {
      await File(
        '${_dir(paths[3]).path}${Platform.pathSeparator}${_safe(p.alignmentId)}.json',
      ).writeAsString(
        jsonEncode({
          'alignmentId': p.alignmentId,
          'translation': p.translation.toJson(),
          'rotation': p.rotation.toJson(),
          'matrix': p.matrix.toJson(),
          'rms': p.rmsError,
          'maximumError': p.maximumError,
          'averageError': p.averageError,
          'confidence': p.confidence,
          'quality': p.estimatedQuality,
          'degreesOfFreedom': p.degreesOfFreedom,
          'lockedAxes': p.lockedAxes.toList(),
        }),
      );
    }
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}mappings.json',
    ).writeAsString(jsonEncode(mappings));
  }
}

class AlignmentRepositoryFactory {
  const AlignmentRepositoryFactory();
  AlignmentRepository create(Directory project) => AlignmentRepository(project);
}
