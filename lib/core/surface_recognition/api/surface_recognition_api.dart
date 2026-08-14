import '../../mesh_foundation/models/mesh_models.dart';
import '../engine/surface_recognition_engine.dart';
import '../models/surface_recognition_models.dart';

class SurfaceRecognitionApi {
  const SurfaceRecognitionApi(this.engine);
  final SurfaceRecognitionEngine engine;
  Future<SurfaceRecognitionReport> run(MeshEntity mesh) =>
      engine.recognize(mesh);
  SurfaceRecognitionReport? forMesh(String meshId) =>
      engine.repository.forMesh(meshId);
  Future<void> persist() => engine.repository.persist();
}
