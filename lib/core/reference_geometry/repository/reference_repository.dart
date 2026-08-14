import 'dart:convert';
import 'dart:io';
import '../analytics/reference_analytics.dart';
import '../history/reference_history.dart';
import '../models/reference_models.dart';
import '../preview/reference_preview.dart';

class ReferenceRepository {
  ReferenceRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/References',
    'CAD/ReferenceHistory',
    'CAD/ReferenceAnalytics',
    'CAD/ReferencePreview',
    'CAD/CoordinateSystems',
    'CAD/ConstructionGeometry',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<ReferenceEntity> references,
    required ReferenceHistory history,
    required ReferenceAnalytics analytics,
    required Iterable<ReferencePreview> previews,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final r in references) {
      final target = r.type == ReferenceType.coordinateSystem
          ? paths[4]
          : {
              ReferenceType.constructionPlane,
              ReferenceType.constructionAxis,
              ReferenceType.constructionPoint,
            }.contains(r.type)
          ? paths[5]
          : paths[0];
      await File(
        '${_dir(target).path}${Platform.pathSeparator}${_safe(r.id)}.json',
      ).writeAsString(jsonEncode(r.toJson()));
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
        '${_dir(paths[3]).path}${Platform.pathSeparator}${_safe(p.referenceId)}.json',
      ).writeAsString(
        jsonEncode({
          'referenceId': p.referenceId,
          'kind': p.kind,
          'origin': p.origin.toJson(),
          'orientation': p.orientation.toJson(),
          'readiness': p.readiness,
          'warnings': p.warnings,
        }),
      );
    }
  }
}

class ReferenceRepositoryFactory {
  const ReferenceRepositoryFactory();
  ReferenceRepository create(Directory project) => ReferenceRepository(project);
}
