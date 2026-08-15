import 'dart:io';
import '../../surface_operations/api/surface_operations_api.dart';
import '../api/advanced_surface_api.dart';
import '../engine/advanced_surface_engine.dart';
import '../repository/advanced_surface_repository.dart';

class AdvancedSurfaceFactory {
  const AdvancedSurfaceFactory();
  AdvancedSurfaceApi create({
    required Directory projectDirectory,
    required SurfaceOperationsApi operations,
  }) => AdvancedSurfaceApi(
    AdvancedSurfaceEngine(
      operations: operations,
      repository: AdvancedSurfaceRepository(projectDirectory),
    ),
  );
}
