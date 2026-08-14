import 'dart:convert';
import 'dart:io';
import '../analytics/transition_analytics.dart';
import '../history/transition_history.dart';
import '../models/transition_models.dart';
import '../preview/transition_preview.dart';

class TransitionRepository {
  TransitionRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Sweeps',
    'CAD/Lofts',
    'CAD/TransitionHistory',
    'CAD/TransitionAnalytics',
    'CAD/TransitionPreview',
    'CAD/TransitionParameters',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<TransitionFeature> features,
    required TransitionHistory history,
    required TransitionAnalytics analytics,
    required Iterable<TransitionPreview> previews,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final feature in features) {
      final folder = feature.family == TransitionFamily.sweep
              ? paths[0]
              : paths[1],
          name = _safe(feature.id);
      await File(
        '${_dir(folder).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(feature.toJson()));
      await File(
        '${_dir(paths[5]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(feature.parameters.toJson()));
    }
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    for (final preview in previews) {
      await File(
        '${_dir(paths[4]).path}${Platform.pathSeparator}${_safe(preview.featureId)}.json',
      ).writeAsString(
        jsonEncode({
          'featureId': preview.featureId,
          'operation': preview.operation,
          'faces': preview.predictedFaces,
          'sections': preview.sections,
          'paths': preview.paths,
          'guides': preview.guides,
          'readiness': preview.readiness,
          'kernelStatus': preview.kernelStatus,
          'warnings': preview.warnings,
          'complexity': preview.complexityScore,
        }),
      );
    }
  }
}

class TransitionRepositoryFactory {
  const TransitionRepositoryFactory();
  TransitionRepository create(Directory project) =>
      TransitionRepository(project);
}
