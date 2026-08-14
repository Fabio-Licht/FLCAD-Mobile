import 'dart:convert';
import 'dart:io';
import '../analytics/validation_analytics.dart';
import '../history/validation_history.dart';
import '../history/validation_timeline.dart';
import '../models/validation_models.dart';
import '../preview/heat_map.dart';

class ValidationRepository {
  ValidationRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Validation',
    'CAD/ValidationHistory',
    'CAD/ValidationTimeline',
    'CAD/ValidationAnalytics',
    'CAD/HeatMaps',
    'CAD/Tolerances',
    'CAD/Baselines',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<LiveValidationSession> sessions,
    required ValidationHistory history,
    required ValidationTimeline timeline,
    required ValidationAnalytics analytics,
    required Iterable<HeatMapPreview> heatMaps,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    for (final session in sessions) {
      final name = _safe(session.id);
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(session.toJson()));
      await File(
        '${_dir(paths[5]).path}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(session.parameters.toJson()));
    }
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}timeline.json',
    ).writeAsString(
      jsonEncode(timeline.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    for (final heat in heatMaps) {
      await File(
        '${_dir(paths[4]).path}${Platform.pathSeparator}${_safe(heat.sessionId)}.json',
      ).writeAsString(
        jsonEncode({
          'sessionId': heat.sessionId,
          'colorScale': heat.colorScale,
          'points': [
            for (final p in heat.points)
              {
                'regionId': p.regionId,
                'deviation': p.deviation,
                'confidence': p.confidence,
                'band': p.band.name,
                'color': p.color,
              },
          ],
          'criticalRegions': heat.criticalRegions,
          'warningRegions': heat.warningRegions,
        }),
      );
    }
    for (final baseline in history.baselines.values) {
      await File(
        '${_dir(paths[6]).path}${Platform.pathSeparator}${_safe(baseline.sessionId)}.json',
      ).writeAsString(jsonEncode(baseline.toJson()));
    }
  }
}

class ValidationRepositoryFactory {
  const ValidationRepositoryFactory();
  ValidationRepository create(Directory project) =>
      ValidationRepository(project);
}
