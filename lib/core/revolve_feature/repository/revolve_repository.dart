import 'dart:convert';
import 'dart:io';
import '../analytics/revolve_analytics.dart';
import '../history/revolve_history.dart';
import '../models/revolve_models.dart';
import '../preview/revolve_preview.dart';

class RevolveRepository {
  RevolveRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Revolves',
    'CAD/RevolveHistory',
    'CAD/RevolveAnalytics',
    'CAD/RevolvePreview',
    'CAD/RevolveParameters',
  ];
  Directory _dir(String p) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<RevolveFeature> revolves,
    required RevolveHistory history,
    required RevolveAnalytics analytics,
    Iterable<RevolvePreview> previews = const [],
  }) async {
    for (final p in paths) {
      await _dir(p).create(recursive: true);
    }
    for (final r in revolves) {
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}${_safe(r.id)}.json',
      ).writeAsString(jsonEncode(r.toJson()));
      await File(
        '${_dir(paths[4]).path}${Platform.pathSeparator}${_safe(r.id)}.json',
      ).writeAsString(jsonEncode(r.parameters.toJson()));
    }
    for (final p in previews) {
      await File(
        '${_dir(paths[3]).path}${Platform.pathSeparator}${_safe(p.revolveId)}.json',
      ).writeAsString(
        jsonEncode({
          'revolveId': p.revolveId,
          'predictedVolume': p.predictedVolume,
          'boundingBox': {
            'width': p.boundingBox.width,
            'height': p.boundingBox.height,
            'depth': p.boundingBox.depth,
          },
          'predictedFaces': p.predictedFaces,
          'angle': p.angle,
          'axis': p.axis.toJson(),
          'direction': p.direction,
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

class RevolveRepositoryFactory {
  const RevolveRepositoryFactory();
  RevolveRepository create(Directory project) => RevolveRepository(project);
}
