import 'dart:io';
import '../../surface_operations/api/surface_operations_api.dart';
import '../api/surface_manufacturing_api.dart';
import '../engine/surface_manufacturing_engine.dart';
import '../repository/surface_manufacturing_repository.dart';

class SurfaceManufacturingFactory {
  const SurfaceManufacturingFactory();
  SurfaceManufacturingApi create({
    required Directory projectDirectory,
    required SurfaceOperationsApi operations,
  }) => SurfaceManufacturingApi(
    SurfaceManufacturingEngine(
      operations: operations,
      repository: SurfaceManufacturingRepository(projectDirectory),
    ),
  );
}
