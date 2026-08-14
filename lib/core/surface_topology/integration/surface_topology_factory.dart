import 'dart:io';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../api/surface_topology_api.dart';
import '../engine/surface_topology_engine.dart';
import '../repository/surface_topology_repository.dart';
import 'surface_topology_integration.dart';

class SurfaceTopologyFactory {
  const SurfaceTopologyFactory();
  SurfaceTopologyApi create({
    required Directory projectDirectory,
    required SurfaceTopologyKernelAPI kernel,
    SurfaceTopologyIntegration? integration,
  }) => SurfaceTopologyApi(
    SurfaceTopologyEngine(
      kernel: kernel,
      repository: SurfaceTopologyRepository(projectDirectory),
      integration: integration,
    ),
  );
}
