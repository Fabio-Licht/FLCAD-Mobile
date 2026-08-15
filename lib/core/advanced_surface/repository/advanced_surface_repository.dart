import 'dart:convert';
import 'dart:io';
import '../models/advanced_surface_models.dart';

class AdvancedSurfaceRepository {
  AdvancedSurfaceRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, AdvancedSurfaceSession> sessions = {};
  static const paths = [
    'CAD/AdvancedSurface',
    'CAD/AdvancedSurfaceHistory',
    'CAD/AdvancedSurfaceAnalytics',
    'CAD/AdvancedSurfaceReports',
    'CAD/GapAnalysis',
    'CAD/SurfaceNetworkAnalysis',
    'CAD/SmartSurfaceAdvisor',
  ];
  void add(AdvancedSurfaceSession value) {
    if (sessions.containsKey(value.id)) {
      throw StateError('Duplicate advanced surface session: ${value.id}');
    }
    sessions[value.id] = value;
  }

  void update(AdvancedSurfaceSession value) {
    if (!sessions.containsKey(value.id)) {
      throw StateError('Unknown advanced surface session: ${value.id}');
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
      await write('CAD/AdvancedSurface', value.toJson());
      await write('CAD/AdvancedSurfaceHistory', value.history);
      await write('CAD/AdvancedSurfaceReports', {
        'preview': value.preview?.toJson(),
        'validation': value.validation?.toJson(),
        'advisor': value.advice?.toJson(),
      });
      if (value.preview != null) {
        await write('CAD/GapAnalysis', value.preview!.gapAnalysis.toJson());
        await write(
          'CAD/SurfaceNetworkAnalysis',
          value.preview!.networkAnalysis.toJson(),
        );
      }
      if (value.type == AdvancedSurfaceType.smartAdvisor) {
        await write('CAD/SmartSurfaceAdvisor', value.toJson());
      }
    }
    await File(
      '${_path('CAD/AdvancedSurfaceAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics));
  }
}
