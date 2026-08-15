import 'dart:convert';
import 'dart:io';
import '../models/surface_boundary_models.dart';

class SurfaceBoundaryRepository {
  SurfaceBoundaryRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceBoundarySession> sessions = {};
  static const paths = [
    'CAD/SurfaceBoundary',
    'CAD/BoundaryHistory',
    'CAD/BoundaryAnalytics',
    'CAD/BoundaryReports',
    'CAD/ManufacturingBoundary',
    'CAD/SmartBoundary',
  ];
  void add(SurfaceBoundarySession value) {
    if (sessions.containsKey(value.id)) {
      throw StateError('Duplicate boundary session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  void update(SurfaceBoundarySession value) {
    if (!sessions.containsKey(value.id)) {
      throw StateError('Unknown boundary session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  String _path(String path) =>
      '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(Map<String, dynamic> analytics) async {
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    for (final value in sessions.values) {
      final name = value.id.replaceAll(':', '_');
      Future<void> write(String path, Object data) => File(
        '${_path(path)}${Platform.pathSeparator}$name.json',
      ).writeAsString(jsonEncode(data));
      await write('CAD/SurfaceBoundary', value.toJson());
      await write('CAD/BoundaryHistory', value.history);
      await write('CAD/BoundaryReports', {
        'preview': value.preview?.toJson(),
        'validation': value.validation?.toJson(),
        'advisor': value.advice?.toJson(),
      });
      if (value.type == BoundaryOperationType.manufacturing) {
        await write('CAD/ManufacturingBoundary', value.toJson());
      }
      if (value.type == BoundaryOperationType.smart) {
        await write('CAD/SmartBoundary', value.toJson());
      }
    }
    await File(
      '${_path('CAD/BoundaryAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics));
  }
}
