import 'dart:io';
import '../../surface_operations/api/surface_operations_api.dart';
import '../api/surface_reduce_api.dart';
import '../engine/surface_reduce_engine.dart';
import '../repository/surface_reduce_repository.dart';

class SurfaceReduceFactory {
  const SurfaceReduceFactory();
  SurfaceReduceApi create({
    required Directory projectDirectory,
    required SurfaceOperationsApi operations,
  }) => SurfaceReduceApi(
    SurfaceReduceEngine(
      operations: operations,
      repository: SurfaceReduceRepository(projectDirectory),
    ),
  );
}
