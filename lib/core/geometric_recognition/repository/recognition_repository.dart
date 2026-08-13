import '../models/recognition_models.dart';

abstract interface class RecognitionRepository {
  Future<void> save(PrimitiveRecognitionResult result);
  Future<List<PrimitiveRecognitionResult>> findAll(String projectId);
  Future<void> clear(String projectId);
}

class InMemoryRecognitionRepository implements RecognitionRepository {
  final Map<String, List<PrimitiveRecognitionResult>> _values = {};
  @override
  Future<void> save(PrimitiveRecognitionResult result) async {
    final values = _values.putIfAbsent(result.projectId, () => []);
    values.removeWhere((item) => item.id == result.id);
    values.add(result);
  }

  @override
  Future<List<PrimitiveRecognitionResult>> findAll(String projectId) async =>
      List.unmodifiable(_values[projectId] ?? const []);
  @override
  Future<void> clear(String projectId) async => _values.remove(projectId);
}
