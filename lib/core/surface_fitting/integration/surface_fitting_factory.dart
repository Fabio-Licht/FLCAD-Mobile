import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../api/surface_fitting_api.dart';
import '../engine/surface_fitting_engine.dart';
import '../repository/surface_fitting_repository.dart';
import 'surface_fitting_integration.dart';

class SurfaceFittingFactory {
  const SurfaceFittingFactory();
  SurfaceFittingApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    SurfaceFittingIntegration? integration,
  }) => SurfaceFittingApi(
    SurfaceFittingEngine(
      kernel: kernel,
      repository: SurfaceFittingRepository(projectDirectory),
      integration: integration,
    ),
  );
}
