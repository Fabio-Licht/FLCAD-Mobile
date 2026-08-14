import 'dart:io';
import '../../live_reconstruction/api/live_reconstruction_api.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../api/surface_morph_api.dart';
import '../engine/surface_morph_engine.dart';
import '../repository/surface_morph_repository.dart';
import 'surface_morph_integration.dart';

class SurfaceMorphFactory {
  const SurfaceMorphFactory();
  SurfaceMorphApi create({
    required Directory projectDirectory,
    required SurfaceOperationsApi operations,
    required LiveReconstructionApi reconstruction,
    SurfaceMorphIntegration? integration,
  }) => SurfaceMorphApi(
    SurfaceMorphEngine(
      operations: operations,
      reconstruction: reconstruction,
      repository: SurfaceMorphRepository(projectDirectory),
      integration: integration,
    ),
  );
}
