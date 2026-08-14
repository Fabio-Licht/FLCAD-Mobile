import 'dart:io';
import '../../surface_operations/api/surface_operations_api.dart';
import '../api/live_reconstruction_api.dart';
import '../engine/live_reconstruction_engine.dart';
import '../repository/live_reconstruction_repository.dart';
import 'live_reconstruction_integration.dart';

class LiveReconstructionFactory {
  const LiveReconstructionFactory();
  LiveReconstructionApi create({
    required Directory projectDirectory,
    required SurfaceOperationsApi operations,
    LiveReconstructionIntegration? integration,
  }) => LiveReconstructionApi(
    LiveReconstructionEngine(
      operations: operations,
      repository: LiveReconstructionRepository(projectDirectory),
      integration: integration,
    ),
  );
}
