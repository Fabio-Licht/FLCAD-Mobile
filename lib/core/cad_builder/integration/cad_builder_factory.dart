import 'dart:io';
import '../../cad_kernel/manager/kernel_manager.dart';
import '../api/cad_builder_api.dart';
import '../engine/cad_builder_engine.dart';
import '../repository/cad_builder_repository.dart';

class CadBuilderFactory {
  const CadBuilderFactory(this.kernels);
  final KernelManager kernels;
  CadBuilderApi create({
    required String projectId,
    required Directory projectDirectory,
  }) {
    if (kernels.active.descriptor.id == 'none') {
      throw StateError('A healthy CAD kernel must be selected');
    }
    return CadBuilderApi(
      CadBuilderEngine(
        projectId: projectId,
        kernel: kernels.active,
        repository: CadBuilderRepository(projectDirectory),
      ),
    );
  }
}
