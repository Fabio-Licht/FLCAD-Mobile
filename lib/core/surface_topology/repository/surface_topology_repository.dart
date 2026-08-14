import 'dart:convert';
import 'dart:io';
import '../models/surface_topology_models.dart';

class SurfaceTopologyRepository {
  SurfaceTopologyRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceTopologyReport> reports = {};
  static const paths = [
    'CAD/Topology',
    'CAD/Patches',
    'CAD/Boundaries',
    'CAD/Loops',
    'CAD/Intersections',
    'CAD/Adjacency',
    'CAD/TopologyAnalytics',
    'CAD/TopologyHistory',
  ];
  void save(SurfaceTopologyReport report) {
    if (reports.containsKey(report.id)) {
      throw StateError('Duplicate topology report: ${report.id}');
    }
    reports[report.id] = report;
  }

  SurfaceTopologyReport? forFitting(String id) =>
      reports.values.where((e) => e.surfaceFittingReportId == id).lastOrNull;
  String _path(String p) =>
      '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist() async {
    for (final p in paths) {
      await Directory(_path(p)).create(recursive: true);
    }
    for (final r in reports.values) {
      final safe = r.id.replaceAll(':', '_');
      Future<void> write(String path, Object value) => File(
        '${_path(path)}${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(value));
      await write('CAD/Topology', r.toJson());
      await write('CAD/Patches', r.patches.map((e) => e.toJson()).toList());
      await write(
        'CAD/Boundaries',
        r.boundaries.map((e) => e.toJson()).toList(),
      );
      await write('CAD/Loops', r.loops.map((e) => e.toJson()).toList());
      await write(
        'CAD/Intersections',
        r.intersections.map((e) => e.toJson()).toList(),
      );
      await write('CAD/Adjacency', r.graph.toJson());
      await write('CAD/TopologyAnalytics', r.analytics.toJson());
      await write('CAD/TopologyHistory', {
        'event': 'Topology built',
        'reportId': r.id,
        'timestamp': r.createdAt.toIso8601String(),
      });
    }
  }
}
