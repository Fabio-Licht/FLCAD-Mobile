import 'dart:io';
import '../../cad_kernel/manager/kernel_manager.dart';
import '../api/feature_api.dart';
import '../engine/feature_engine.dart';
import '../repository/feature_repository.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../engineering/history/engineering_history.dart';

class FeatureFactory {
  const FeatureFactory(this.kernels);
  final KernelManager kernels;
  FeatureApi create({
    required String projectId,
    required Directory projectDirectory,
    EngineeringHistory? engineeringHistory,
    EngineeringGraph? engineeringGraph,
  }) {
    if (kernels.active.descriptor.id == 'none') {
      throw StateError('A healthy CAD kernel must be selected');
    }
    return FeatureApi(
      FeatureEngine(
        projectId: projectId,
        kernel: kernels.active,
        repository: FeatureRepository(projectDirectory),
        engineeringHistory: engineeringHistory,
        engineeringGraph: engineeringGraph,
      ),
    );
  }
}
