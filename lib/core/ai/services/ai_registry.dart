import '../models/ai_model_metadata.dart';

class AIRegistry {
  final Map<String, AIModelMetadata> _models = {};
  List<AIModelMetadata> get installedModels =>
      List.unmodifiable(_models.values);
  void register(AIModelMetadata metadata) => _models[metadata.id] = metadata;
  void unregister(String id) => _models.remove(id);
}
