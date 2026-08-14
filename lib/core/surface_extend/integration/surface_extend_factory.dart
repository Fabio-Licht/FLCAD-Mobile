import 'dart:io';
import '../../surface_morph/api/surface_morph_api.dart';
import '../api/surface_extend_api.dart';
import '../engine/surface_extend_engine.dart';
import '../repository/surface_extend_repository.dart';
import 'surface_extend_integration.dart';

class SurfaceExtendFactory {
  const SurfaceExtendFactory();
  SurfaceExtendApi create({
    required Directory projectDirectory,
    required SurfaceMorphApi morph,
    SurfaceExtendIntegration? integration,
  }) => SurfaceExtendApi(
    SurfaceExtendEngine(
      morph: morph,
      repository: SurfaceExtendRepository(projectDirectory),
      integration: integration,
    ),
  );
}
