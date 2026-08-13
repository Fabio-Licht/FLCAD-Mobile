import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../graph/surface_dependency_graph.dart';
import '../models/surface_models.dart';

class SurfaceIntelligenceRepository {
  const SurfaceIntelligenceRepository(this.projectDirectory);
  final Directory projectDirectory;
  Directory get plans =>
      Directory(path.join(projectDirectory.path, 'SurfacePlanning'));
  Directory get candidates =>
      Directory(path.join(projectDirectory.path, 'SurfaceCandidates'));
  Directory get strategies =>
      Directory(path.join(projectDirectory.path, 'SurfaceStrategies'));
  Directory get graph =>
      Directory(path.join(projectDirectory.path, 'SurfaceGraph'));
  Future<void> initialize() async {
    for (final directory in [plans, candidates, strategies, graph]) {
      await directory.create(recursive: true);
    }
  }

  Future<void> save(SurfacePlan plan, SurfaceDependencyGraph value) async {
    await initialize();
    await File(
      path.join(plans.path, '${plan.id}.json'),
    ).writeAsString(jsonEncode(plan.toJson()), flush: true);
    await File(path.join(candidates.path, '${plan.id}.json')).writeAsString(
      jsonEncode(plan.candidates.map((e) => e.toJson()).toList()),
      flush: true,
    );
    await File(path.join(strategies.path, '${plan.id}.json')).writeAsString(
      jsonEncode(plan.strategies.map((e) => e.toJson()).toList()),
      flush: true,
    );
    await File(
      path.join(graph.path, '${plan.id}.json'),
    ).writeAsString(jsonEncode(value.toJson()), flush: true);
  }
}
