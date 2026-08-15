import 'dart:convert';
import 'dart:io';
import '../models/surface_fair_models.dart';

class SurfaceFairRepository {
  SurfaceFairRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceFairSession> sessions = {};
  static const paths = [
    'CAD/SurfaceFair',
    'CAD/FairHistory',
    'CAD/FairAnalytics',
    'CAD/FairReports',
    'CAD/ManufacturingFair',
    'CAD/SmartFair',
  ];
  void add(SurfaceFairSession value) {
    if (sessions.containsKey(value.id)) {
      throw StateError('Duplicate fair session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  void update(SurfaceFairSession value) {
    if (!sessions.containsKey(value.id)) {
      throw StateError('Unknown fair session: ${value.id}');
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
      await write('CAD/SurfaceFair', value.toJson());
      await write('CAD/FairHistory', value.history);
      await write('CAD/FairReports', {
        'prediction': value.prediction?.toJson(),
        'validation': value.validation?.toJson(),
        'advisor': value.advice?.toJson(),
      });
      if (value.type == FairType.manufacturingFair) {
        await write('CAD/ManufacturingFair', value.toJson());
      }
      if (value.type == FairType.smartFair) {
        await write('CAD/SmartFair', value.toJson());
      }
    }
    await File(
      '${_path('CAD/FairAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics));
  }
}
