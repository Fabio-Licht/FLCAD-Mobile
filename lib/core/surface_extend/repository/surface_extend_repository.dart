import 'dart:convert';
import 'dart:io';
import '../models/surface_extend_models.dart';

class SurfaceExtendRepository {
  SurfaceExtendRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, ExtendSession> sessions = {};
  static const paths = [
    'CAD/SurfaceExtend',
    'CAD/ExtendHistory',
    'CAD/ExtendAnalytics',
    'CAD/ExtendReports',
    'CAD/ManufacturingExtend',
    'CAD/SmartExtend',
  ];
  void add(ExtendSession v) {
    if (sessions.containsKey(v.id)) {
      throw StateError('Duplicate extend session: ${v.id}');
    }
    sessions[v.id] = v;
  }

  void update(ExtendSession v) {
    if (!sessions.containsKey(v.id)) {
      throw StateError('Unknown extend session: ${v.id}');
    }
    sessions[v.id] = v;
  }

  String _path(String p) =>
      '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(Map<String, dynamic> analytics) async {
    for (final p in paths) {
      await Directory(_path(p)).create(recursive: true);
    }
    for (final v in sessions.values) {
      final n = v.id.replaceAll(':', '_');
      Future<void> write(String p, Object d) => File(
        '${_path(p)}${Platform.pathSeparator}$n.json',
      ).writeAsString(jsonEncode(d));
      await write('CAD/SurfaceExtend', v.toJson());
      await write('CAD/ExtendHistory', v.history);
      await write('CAD/ExtendReports', {
        'analysis': v.analysis?.toJson(),
        'validation': v.validation?.toJson(),
      });
      if (v.type == ExtendType.manufacturing) {
        await write('CAD/ManufacturingExtend', v.toJson());
      }
      if (v.type == ExtendType.smart) {
        await write('CAD/SmartExtend', v.toJson());
      }
    }
    await File(
      '${_path('CAD/ExtendAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics));
  }
}
