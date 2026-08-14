import 'dart:convert';
import 'dart:io';

import '../models/surface_fitting_models.dart';

class SurfaceFittingRepository {
  SurfaceFittingRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceFittingReport> reports = {};
  static const paths = [
    'CAD/Surfaces',
    'CAD/SurfaceTree',
    'CAD/SurfaceAnalytics',
    'CAD/SurfaceReports',
    'CAD/SurfaceHistory',
    'CAD/SurfaceValidation',
  ];
  void save(SurfaceFittingReport report) {
    if (reports.containsKey(report.id)) {
      throw StateError('Duplicate surface fitting report: ${report.id}');
    }
    reports[report.id] = report;
  }

  SurfaceFittingReport? forRecognition(String id) =>
      reports.values.where((e) => e.recognitionReportId == id).lastOrNull;
  Future<void> persist() async {
    for (final path in paths) {
      await Directory(
        '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
      ).create(recursive: true);
    }
    for (final report in reports.values) {
      final safe = report.id.replaceAll(':', '_'),
          json = jsonEncode(report.toJson());
      await File(
        '${_path('CAD/SurfaceReports')}${Platform.pathSeparator}$safe.json',
      ).writeAsString(json);
      await File(
        '${_path('CAD/Surfaces')}${Platform.pathSeparator}$safe.json',
      ).writeAsString(
        jsonEncode(report.surfaces.map((e) => e.toJson()).toList()),
      );
      await File(
        '${_path('CAD/SurfaceTree')}${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(_tree(report)));
      await File(
        '${_path('CAD/SurfaceAnalytics')}${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(report.analytics.toJson()));
      await File(
        '${_path('CAD/SurfaceValidation')}${Platform.pathSeparator}$safe.json',
      ).writeAsString(
        jsonEncode({
          'accepted': report.analytics.accepted,
          'rejected': report.analytics.rejected,
        }),
      );
      await File(
        '${_path('CAD/SurfaceHistory')}${Platform.pathSeparator}$safe.json',
      ).writeAsString(
        jsonEncode({
          'event': 'Surface fitting completed',
          'reportId': report.id,
          'timestamp': report.createdAt.toIso8601String(),
        }),
      );
    }
  }

  String _path(String value) =>
      '${projectDirectory.path}${Platform.pathSeparator}${value.replaceAll('/', Platform.pathSeparator)}';
  Map<String, dynamic> _tree(SurfaceFittingReport report) => {
    'Surface Reconstruction': {
      'Planes': _of(report, 'plane'),
      'Cylinders': _of(report, 'cylinder'),
      'Cones': _of(report, 'cone'),
      'Spheres': _of(report, 'sphere'),
      'Tori': _of(report, 'torus'),
      'Failed Fits': report.surfaces
          .where((e) => e.status != SurfaceFitStatus.accepted)
          .map((e) => e.toJson())
          .toList(),
    },
  };
  List<Map<String, dynamic>> _of(SurfaceFittingReport report, String type) =>
      report.surfaces
          .where(
            (e) =>
                e.primitiveType.name == type &&
                e.status == SurfaceFitStatus.accepted,
          )
          .map((e) => e.toJson())
          .toList();
}
