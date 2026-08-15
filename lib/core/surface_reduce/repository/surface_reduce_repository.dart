import 'dart:convert';
import 'dart:io';
import '../models/surface_reduce_models.dart';

class SurfaceReduceRepository {
  SurfaceReduceRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceReduceSession> sessions = {};
  static const paths = [
    'CAD/SurfaceReduce',
    'CAD/ReduceHistory',
    'CAD/ReduceAnalytics',
    'CAD/ReduceReports',
    'CAD/ManufacturingReduce',
    'CAD/SmartReduce',
  ];
  void add(SurfaceReduceSession value) {
    if (sessions.containsKey(value.id)) {
      throw StateError('Duplicate reduce session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  void update(SurfaceReduceSession value) {
    if (!sessions.containsKey(value.id)) {
      throw StateError('Unknown reduce session: ${value.id}');
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
      await write('CAD/SurfaceReduce', value.toJson());
      await write('CAD/ReduceHistory', value.history);
      await write('CAD/ReduceReports', {
        'prediction': value.prediction?.toJson(),
        'validation': value.validation?.toJson(),
        'advisor': value.advice?.toJson(),
      });
      if (value.type == ReduceType.manufacturing) {
        await write('CAD/ManufacturingReduce', value.toJson());
      }
      if (value.type == ReduceType.smart) {
        await write('CAD/SmartReduce', value.toJson());
      }
    }
    await File(
      '${_path('CAD/ReduceAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics));
  }
}
