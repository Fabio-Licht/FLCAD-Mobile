import 'dart:convert';
import 'dart:io';
import '../analytics/feature_analytics.dart';
import '../graph/feature_graph.dart';
import '../history/feature_history.dart';
import '../models/feature_models.dart';
import '../parameters/feature_parameters.dart';
import '../timeline/feature_timeline.dart';

class FeatureRepository {
  FeatureRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Features',
    'CAD/FeatureHistory',
    'CAD/FeatureGraph',
    'CAD/FeatureTimeline',
    'CAD/FeatureParameters',
    'CAD/FeatureAnalytics',
  ];
  Directory _dir(String p) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<FeatureInstance> features,
    required FeatureHistory history,
    required FeatureGraphSet graphs,
    required FeatureTimeline timeline,
    required FeatureParameterSet parameters,
    required FeatureAnalytics analytics,
  }) async {
    for (final p in paths) {
      await _dir(p).create(recursive: true);
    }
    for (final f in features) {
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}${_safe(f.id)}.json',
      ).writeAsString(jsonEncode(f.toJson()));
    }
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}graph.json',
    ).writeAsString(jsonEncode(graphs.toJson()));
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}timeline.json',
    ).writeAsString(jsonEncode(timeline.toJson()));
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}parameters.json',
    ).writeAsString(jsonEncode(parameters.toJson()));
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
  }
}

class FeatureRepositoryFactory {
  const FeatureRepositoryFactory();
  FeatureRepository create(Directory project) => FeatureRepository(project);
}
