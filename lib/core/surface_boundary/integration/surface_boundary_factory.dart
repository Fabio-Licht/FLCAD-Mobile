import 'dart:io';
import '../../surface_operations/api/surface_operations_api.dart';
import '../api/surface_boundary_api.dart';
import '../engine/surface_boundary_engine.dart';
import '../repository/surface_boundary_repository.dart';

class SurfaceBoundaryFactory {
  const SurfaceBoundaryFactory();
  SurfaceBoundaryApi create({
    required Directory projectDirectory,
    required SurfaceOperationsApi operations,
  }) => SurfaceBoundaryApi(
    SurfaceBoundaryEngine(
      operations: operations,
      repository: SurfaceBoundaryRepository(projectDirectory),
    ),
  );
}
