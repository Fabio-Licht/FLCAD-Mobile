import 'dart:convert';
import 'dart:io';

import '../models/surface_recognition_models.dart';

class SurfaceRecognitionRepository {
  SurfaceRecognitionRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceRecognitionReport> reports = {};
  static const paths = [
    'CAD/Recognition',
    'CAD/RecognitionTree',
    'CAD/RecognitionReports',
    'CAD/RecognitionAnalytics',
    'CAD/RecognitionHistory',
    'CAD/RecognitionRegions',
    'CAD/RecognitionConfidence',
  ];
  void save(SurfaceRecognitionReport report) {
    if (reports.containsKey(report.id)) {
      throw StateError('Duplicate recognition id: ${report.id}');
    }
    reports[report.id] = report;
  }

  SurfaceRecognitionReport? forMesh(String meshId) =>
      reports.values.where((r) => r.meshId == meshId).lastOrNull;
  Future<void> persist() async {
    for (final path in paths) {
      await Directory(
        '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
      ).create(recursive: true);
    }
    for (final report in reports.values) {
      final json = jsonEncode(report.toJson()),
          safe = report.id.replaceAll(':', '_');
      await File(
        '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}RecognitionReports${Platform.pathSeparator}$safe.json',
      ).writeAsString(json);
      await File(
        '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}RecognitionRegions${Platform.pathSeparator}$safe.json',
      ).writeAsString(
        jsonEncode(report.classifications.map((e) => e.toJson()).toList()),
      );
      await File(
        '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}RecognitionTree${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(_tree(report)));
      await File(
        '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}RecognitionAnalytics${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(report.analytics.toJson()));
      await File(
        '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}RecognitionConfidence${Platform.pathSeparator}$safe.json',
      ).writeAsString(
        jsonEncode({
          for (final c in report.classifications) c.region.id: c.confidence,
        }),
      );
    }
  }

  Map<String, dynamic> _tree(SurfaceRecognitionReport report) => {
    'Recognition': {
      for (final type in [
        'plane',
        'cylinder',
        'cone',
        'sphere',
        'torus',
        'freeform',
        'unknown',
      ])
        '${type}s': report.classifications
            .where((e) => e.type.name == type)
            .map(
              (e) => {
                'id': e.region.id,
                'color': e.region.color,
                'area': e.region.area,
                'confidence': e.confidence,
                'selected': false,
                'highlighted': false,
              },
            )
            .toList(),
    },
  };
}
