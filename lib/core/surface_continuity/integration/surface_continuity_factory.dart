import 'dart:io';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../api/surface_continuity_api.dart';
import '../engine/surface_continuity_engine.dart';
import '../repository/surface_continuity_repository.dart';
import 'surface_continuity_integration.dart';

class SurfaceContinuityFactory {
  const SurfaceContinuityFactory();
  SurfaceContinuityApi create({
    required Directory projectDirectory,
    required SurfaceQualityKernelAPI kernel,
    SurfaceContinuityIntegration? integration,
    SurfaceContinuitySettings settings = const SurfaceContinuitySettings(),
  }) => SurfaceContinuityApi(
    SurfaceContinuityEngine(
      kernel: kernel,
      repository: SurfaceContinuityRepository(projectDirectory),
      integration: integration,
      settings: settings,
    ),
  );
}
