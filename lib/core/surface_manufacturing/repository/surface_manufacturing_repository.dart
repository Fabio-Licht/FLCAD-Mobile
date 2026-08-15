import 'dart:convert';
import 'dart:io';
import '../models/surface_manufacturing_models.dart';

class SurfaceManufacturingRepository {
  SurfaceManufacturingRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceManufacturingSession> sessions = {};
  static const paths = [
    'CAD/SurfaceManufacturing',
    'CAD/ManufacturingHistory',
    'CAD/ManufacturingAnalytics',
    'CAD/ManufacturingReports',
    'CAD/ManufacturingIntent',
    'CAD/SmartManufacturing',
  ];
  void add(SurfaceManufacturingSession value) {
    if (sessions.containsKey(value.id)) {
      throw StateError('Duplicate manufacturing session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  void update(SurfaceManufacturingSession value) {
    if (!sessions.containsKey(value.id)) {
      throw StateError('Unknown manufacturing session: ${value.id}');
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
      await write('CAD/SurfaceManufacturing', value.toJson());
      await write('CAD/ManufacturingHistory', value.history);
      await write('CAD/ManufacturingReports', {
        'preview': value.preview?.toJson(),
        'validation': value.validation?.toJson(),
        'advisor': value.advice?.toJson(),
      });
      await write('CAD/ManufacturingIntent', value.intent.toJson());
      if (value.type == ManufacturingOperationType.smartManufacturing) {
        await write('CAD/SmartManufacturing', value.toJson());
      }
    }
    await File(
      '${_path('CAD/ManufacturingAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics));
  }
}
