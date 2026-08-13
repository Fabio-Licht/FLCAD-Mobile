import 'dart:io';
import '../api/surface_api.dart';
import '../engine/surface_intelligence_engine.dart';
import '../repository/surface_repository.dart';

class SurfaceIntelligenceFactory {
  const SurfaceIntelligenceFactory();
  SurfaceIntelligenceApi create({required Directory projectDirectory}) =>
      SurfaceIntelligenceApi(
        SurfaceIntelligenceEngine(
          repository: SurfaceIntelligenceRepository(projectDirectory),
        ),
      );
}
