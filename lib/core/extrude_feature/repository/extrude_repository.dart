import 'dart:convert';
import 'dart:io';
import '../analytics/extrude_analytics.dart';
import '../history/extrude_history.dart';
import '../models/extrude_models.dart';
import '../preview/extrude_preview.dart';

class ExtrudeRepository {
  ExtrudeRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Extrudes',
    'CAD/ExtrudeHistory',
    'CAD/ExtrudeAnalytics',
    'CAD/ExtrudePreview',
    'CAD/ExtrudeParameters',
  ];
  Directory _dir(String p) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<ExtrudeFeature> extrudes,
    required ExtrudeHistory history,
    required ExtrudeAnalytics analytics,
    Iterable<ExtrudePreview> previews = const [],
  }) async {
    for (final p in paths) {
      await _dir(p).create(recursive: true);
    }
    for (final e in extrudes) {
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}${_safe(e.id)}.json',
      ).writeAsString(jsonEncode(e.toJson()));
      await File(
        '${_dir(paths[4]).path}${Platform.pathSeparator}${_safe(e.id)}.json',
      ).writeAsString(jsonEncode(e.parameters.toJson()));
    }
    for (final p in previews) {
      await File(
        '${_dir(paths[3]).path}${Platform.pathSeparator}${_safe(p.extrudeId)}.json',
      ).writeAsString(
        jsonEncode({
          'extrudeId': p.extrudeId,
          'predictedVolume': p.predictedVolume,
          'boundingBox': {
            'width': p.boundingBox.width,
            'height': p.boundingBox.height,
            'depth': p.boundingBox.depth,
          },
          'predictedFaces': p.predictedFaces,
          'operation': p.operation,
          'color': p.color,
          'warnings': p.warnings,
          'readiness': p.readiness,
          'kernelStatus': p.kernelStatus,
        }),
      );
    }
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
  }
}

class ExtrudeRepositoryFactory {
  const ExtrudeRepositoryFactory();
  ExtrudeRepository create(Directory project) => ExtrudeRepository(project);
}
