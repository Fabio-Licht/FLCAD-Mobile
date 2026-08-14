import 'dart:convert';
import 'dart:io';
import '../analytics/intelligence_analytics.dart';
import '../history/intelligence_history.dart';
import '../models/intelligence_models.dart';

class IntelligenceRepository {
  IntelligenceRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Engineering',
    'CAD/Recommendations',
    'CAD/Diagnostics',
    'CAD/EngineeringHistory',
    'CAD/EngineeringAnalytics',
    'CAD/EngineeringScore',
    'CAD/ProjectHealth',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  Future<void> save({
    required Iterable<EngineeringAnalysis> analyses,
    required Iterable<EngineeringRecommendation> recommendations,
    required Iterable<EngineeringDiagnostic> diagnostics,
    required IntelligenceHistory history,
    required IntelligenceAnalytics analytics,
    EngineeringScore? score,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    await File(
      '${_dir(paths[0]).path}${Platform.pathSeparator}analyses.json',
    ).writeAsString(jsonEncode(analyses.map((e) => e.toJson()).toList()));
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}recommendations.json',
    ).writeAsString(
      jsonEncode(recommendations.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}diagnostics.json',
    ).writeAsString(jsonEncode(diagnostics.map((e) => e.toJson()).toList()));
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
    if (score != null) {
      await File(
        '${_dir(paths[5]).path}${Platform.pathSeparator}score.json',
      ).writeAsString(jsonEncode(score.toJson()));
      await File(
        '${_dir(paths[6]).path}${Platform.pathSeparator}health.json',
      ).writeAsString(
        jsonEncode({
          'projectHealth': score.projectHealth,
          'overall': score.overall,
        }),
      );
    }
  }
}

class IntelligenceRepositoryFactory {
  const IntelligenceRepositoryFactory();
  IntelligenceRepository create(Directory project) =>
      IntelligenceRepository(project);
}
