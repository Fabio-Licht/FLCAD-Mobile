import 'dart:io';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../api/surface_operations_api.dart';
import '../engine/surface_operations_engine.dart';
import '../repository/surface_operation_repository.dart';
import 'surface_operations_integration.dart';

class SurfaceOperationsFactory {
  const SurfaceOperationsFactory();
  SurfaceOperationsApi create({
    required Directory projectDirectory,
    required SurfaceOperationKernelAPI kernel,
    SurfaceOperationsIntegration? integration,
  }) => SurfaceOperationsApi(
    SurfaceOperationsEngine(
      kernel: kernel,
      repository: SurfaceOperationRepository(projectDirectory),
      integration: integration,
    ),
  );
}
