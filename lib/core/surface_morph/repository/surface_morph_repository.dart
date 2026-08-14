import 'dart:convert';
import 'dart:io';
import '../models/surface_morph_models.dart';

class SurfaceMorphRepository {
  SurfaceMorphRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, MorphSession> sessions = {};
  static const paths = [
    'CAD/SurfaceMorph',
    'CAD/MorphHistory',
    'CAD/Anchors',
    'CAD/MorphConstraints',
    'CAD/MorphAnalytics',
    'CAD/MorphReports',
  ];
  void add(MorphSession value) {
    if (sessions.containsKey(value.id)) {
      throw StateError('Duplicate morph session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  void update(MorphSession value) {
    if (!sessions.containsKey(value.id)) {
      throw StateError('Unknown morph session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  String _path(String path) =>
      '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(Map<String, dynamic> aggregate) async {
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    for (final value in sessions.values) {
      final safe = value.id.replaceAll(':', '_');
      Future<void> write(String folder, Object data) => File(
        '${_path(folder)}${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(data));
      await write('CAD/SurfaceMorph', value.toJson());
      await write('CAD/MorphHistory', value.history);
      await write('CAD/Anchors', value.anchors.map((e) => e.toJson()).toList());
      await write(
        'CAD/MorphConstraints',
        value.constraintGroups.map((e) => e.toJson()).toList(),
      );
      await write('CAD/MorphReports', {
        'status': value.status.name,
        'validation': value.validation?.toJson(),
        'advisor': value.advice.map((e) => e.toJson()).toList(),
      });
    }
    await File(
      '${_path('CAD/MorphAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(aggregate));
  }
}
