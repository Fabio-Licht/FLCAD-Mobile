import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/hybrid_surface_models.dart';
import '../network/surface_network.dart';

class HybridSurfaceRepository {
  const HybridSurfaceRepository(this.projectDirectory);
  final Directory projectDirectory;
  Directory get hybrid =>
      Directory(path.join(projectDirectory.path, 'HybridSurface'));
  Directory get network =>
      Directory(path.join(projectDirectory.path, 'SurfaceNetwork'));
  Directory get strategies =>
      Directory(path.join(projectDirectory.path, 'HybridStrategies'));
  Directory get patches =>
      Directory(path.join(projectDirectory.path, 'PatchPlanning'));
  Directory get reconstruction =>
      Directory(path.join(projectDirectory.path, 'ReconstructionNetwork'));
  Future<void> initialize() async {
    for (final d in [hybrid, network, strategies, patches, reconstruction]) {
      await d.create(recursive: true);
    }
  }

  Future<void> save(HybridSurfacePlan plan, HybridSurfaceNetwork value) async {
    await initialize();
    await File(path.join(hybrid.path, '${plan.id}.json')).writeAsString(
      jsonEncode({
        'id': plan.id,
        'projectId': plan.projectId,
        'selectedStrategyId': plan.selectedStrategyId,
        'valid': plan.valid,
        'diagnostics': plan.diagnostics,
      }),
      flush: true,
    );
    await File(
      path.join(network.path, '${plan.id}.json'),
    ).writeAsString(jsonEncode(value.toJson()), flush: true);
    await File(path.join(strategies.path, '${plan.id}.json')).writeAsString(
      jsonEncode(plan.strategies.map((e) => e.toJson()).toList()),
      flush: true,
    );
    await File(path.join(patches.path, '${plan.id}.json')).writeAsString(
      jsonEncode(plan.patchPlans.map((e) => e.toJson()).toList()),
      flush: true,
    );
    await File(path.join(reconstruction.path, '${plan.id}.json')).writeAsString(
      jsonEncode(plan.reconstructionNodes.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }
}
