import '../../mesh_foundation/models/mesh_models.dart';
import '../../surface_recognition/models/surface_recognition_models.dart';
import '../engine/surface_fitting_engine.dart';
import '../models/surface_fitting_models.dart';

class SurfaceFittingApi {
  const SurfaceFittingApi(this.engine);
  final SurfaceFittingEngine engine;
  Future<SurfaceFittingReport> run({
    required MeshEntity mesh,
    required SurfaceRecognitionReport recognition,
    required String projectId,
  }) => engine.fit(mesh: mesh, recognition: recognition, projectId: projectId);
  SurfaceFittingReport? forRecognition(String id) =>
      engine.repository.forRecognition(id);
  Future<void> persist() => engine.repository.persist();
}
