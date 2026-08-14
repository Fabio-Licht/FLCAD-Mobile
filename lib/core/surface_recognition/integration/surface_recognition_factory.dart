import 'dart:io';

import '../../cad_kernel/io/kernel_io_models.dart';
import '../api/surface_recognition_api.dart';
import '../engine/surface_recognition_engine.dart';
import '../models/surface_recognition_models.dart';
import '../repository/surface_recognition_repository.dart';
import 'surface_recognition_integration.dart';

class SurfaceRecognitionFactory {
  const SurfaceRecognitionFactory();
  SurfaceRecognitionApi create({
    required Directory projectDirectory,
    required MeshGeometryKernelAPI kernel,
    SurfaceRecognitionIntegration? integration,
    SurfaceRecognitionSettings settings = const SurfaceRecognitionSettings(),
  }) => SurfaceRecognitionApi(
    SurfaceRecognitionEngine(
      kernel: kernel,
      repository: SurfaceRecognitionRepository(projectDirectory),
      integration: integration,
      settings: settings,
    ),
  );
}
