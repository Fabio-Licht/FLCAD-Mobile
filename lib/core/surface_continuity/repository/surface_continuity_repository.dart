import 'dart:convert';
import 'dart:io';
import '../models/surface_continuity_models.dart';

class SurfaceContinuityRepository {
  SurfaceContinuityRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceQualityReport> reports = {};
  static const paths = [
    'CAD/Continuity',
    'CAD/SurfaceQuality',
    'CAD/Curvature',
    'CAD/Zebra',
    'CAD/Reflection',
    'CAD/Draft',
    'CAD/QualityReports',
    'CAD/QualityHistory',
  ];
  void save(SurfaceQualityReport report) {
    if (reports.containsKey(report.id)) {
      throw StateError('Duplicate quality report: ${report.id}');
    }
    reports[report.id] = report;
  }

  SurfaceQualityReport? forTopology(String id) =>
      reports.values.where((e) => e.topologyReportId == id).lastOrNull;
  String _path(String p) =>
      '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist() async {
    for (final p in paths) {
      await Directory(_path(p)).create(recursive: true);
    }
    for (final r in reports.values) {
      final safe = r.id.replaceAll(':', '_');
      Future<void> write(String p, Object v) => File(
        '${_path(p)}${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(v));
      await write(
        'CAD/Continuity',
        r.continuity.map((e) => e.toJson()).toList(),
      );
      await write(
        'CAD/SurfaceQuality',
        r.patchQualities.map((e) => e.toJson()).toList(),
      );
      await write(
        'CAD/Curvature',
        r.patchQualities.map((e) => e.curvature.toJson()).toList(),
      );
      await write(
        'CAD/Zebra',
        r.patchQualities.map((e) => e.zebra.toJson()).toList(),
      );
      await write(
        'CAD/Reflection',
        r.patchQualities.map((e) => e.reflection.toJson()).toList(),
      );
      await write(
        'CAD/Draft',
        r.patchQualities.map((e) => e.draft.toJson()).toList(),
      );
      await write('CAD/QualityReports', r.toJson());
      await write('CAD/QualityHistory', {
        'event': 'Surface quality analyzed',
        'reportId': r.id,
        'timestamp': r.createdAt.toIso8601String(),
      });
    }
  }
}
