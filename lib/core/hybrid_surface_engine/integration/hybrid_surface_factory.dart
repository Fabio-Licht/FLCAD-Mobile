import 'dart:io';
import '../api/hybrid_surface_api.dart';
import '../engine/hybrid_surface_engine.dart';
import '../repository/hybrid_surface_repository.dart';

class HybridSurfaceFactory {
  const HybridSurfaceFactory();
  HybridSurfaceApi create({required Directory projectDirectory}) =>
      HybridSurfaceApi(
        HybridSurfaceEngine(
          repository: HybridSurfaceRepository(projectDirectory),
        ),
      );
}
