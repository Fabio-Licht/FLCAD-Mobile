import '../engine/geometric_recognition_engine.dart';
import '../models/recognition_models.dart';

class RecognitionApi {
  RecognitionApi({GeometricRecognitionEngine? engine})
    : engine = engine ?? GeometricRecognitionEngine();
  final GeometricRecognitionEngine engine;
  Future<PrimitiveRecognitionResult> recognize(
    RecognitionContext context, {
    bool rebuild = false,
    void Function(double)? onProgress,
  }) => engine.recognize(context, rebuild: rebuild, onProgress: onProgress);
  Future<List<PrimitiveRecognitionResult>> list(String projectId) =>
      engine.repository.findAll(projectId);
  PrimitiveRecognitionResult explain(String id) =>
      engine.graph.find(id) ?? (throw StateError('Recognition $id not found'));
  Future<void> clear(String projectId) async {
    engine.cache.clear();
    await engine.repository.clear(projectId);
  }
}
