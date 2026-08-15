import 'dart:io';
import '../../surface_operations/api/surface_operations_api.dart';
import '../api/surface_fair_api.dart';
import '../engine/surface_fair_engine.dart';
import '../repository/surface_fair_repository.dart';

class SurfaceFairFactory {
  const SurfaceFairFactory();
  SurfaceFairApi create({
    required Directory projectDirectory,
    required SurfaceOperationsApi operations,
  }) => SurfaceFairApi(
    SurfaceFairEngine(
      operations: operations,
      repository: SurfaceFairRepository(projectDirectory),
    ),
  );
}
