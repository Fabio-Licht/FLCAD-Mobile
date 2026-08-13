import 'dart:io';
import '../../cad_kernel/manager/kernel_manager.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../engineering/history/engineering_history.dart';
import '../api/surface_generation_api.dart';
import '../engine/surface_generation_engine.dart';
import '../repository/surface_generation_repository.dart';

class SurfaceGenerationFactory {
  const SurfaceGenerationFactory(this.kernels);
  final KernelManager kernels;
  SurfaceGenerationApi create({
    required String projectId,
    required Directory projectDirectory,
    EngineeringGraph? engineeringGraph,
    EngineeringHistory? engineeringHistory,
  }) {
    if (kernels.active.descriptor.id == 'none') {
      throw StateError('A healthy CAD kernel must be selected');
    }
    return SurfaceGenerationApi(
      SurfaceGenerationEngine(
        projectId: projectId,
        kernel: kernels.active,
        repository: SurfaceGenerationRepository(projectDirectory),
        engineeringGraph: engineeringGraph,
        engineeringHistory: engineeringHistory,
      ),
    );
  }
}
