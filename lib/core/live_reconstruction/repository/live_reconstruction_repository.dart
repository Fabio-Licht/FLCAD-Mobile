import 'dart:convert';
import 'dart:io';
import '../models/live_reconstruction_models.dart';

class LiveReconstructionRepository {
  LiveReconstructionRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, LiveReconstruction> reconstructions = {};
  static const paths = [
    'CAD/LiveReconstruction',
    'CAD/ReconstructionHistory',
    'CAD/ReconstructionAnalytics',
    'CAD/ReconstructionReports',
    'CAD/DependencyGraph',
    'CAD/Pipeline',
  ];
  void add(LiveReconstruction value) {
    if (reconstructions.containsKey(value.id)) {
      throw StateError('Duplicate live reconstruction: ${value.id}');
    }
    reconstructions[value.id] = value;
  }

  void update(LiveReconstruction value) {
    if (!reconstructions.containsKey(value.id)) {
      throw StateError('Unknown live reconstruction: ${value.id}');
    }
    reconstructions[value.id] = value;
  }

  String _path(String path) =>
      '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(Map<String, dynamic> aggregate) async {
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    for (final value in reconstructions.values) {
      final safe = value.id.replaceAll(':', '_');
      Future<void> write(String folder, Object data) => File(
        '${_path(folder)}${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(data));
      await write('CAD/LiveReconstruction', value.toJson());
      await write('CAD/ReconstructionHistory', value.timeline);
      await write('CAD/ReconstructionReports', {
        'state': value.state.name,
        'validation': value.validation?.toJson(),
        'advisor': value.advice.map((e) => e.toJson()).toList(),
      });
      await write('CAD/DependencyGraph', value.graph.toJson());
      await write('CAD/Pipeline', {
        'id': value.id,
        'state': value.state.name,
        'updatedObjects': value.updatedObjects.toList(),
      });
    }
    await File(
      '${_path('CAD/ReconstructionAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(aggregate));
  }
}
