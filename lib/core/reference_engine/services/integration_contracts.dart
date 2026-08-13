import '../models/reference_entity.dart';

abstract interface class ReferenceRecognizer {
  Future<List<ReferenceRecipe>> recognize(String projectId, String sourceId);
}

abstract interface class ReferenceAdvisor {
  Future<List<String>> advise(ReferenceEntity reference);
}

abstract interface class ReferencePredictor {
  Future<double> match(ReferenceEntity previous, ReferenceEntity candidate);
}

abstract interface class ReferenceClassifier {
  Future<String> classify(ReferenceEntity reference);
}

abstract interface class ReferenceOptimizer {
  Future<ReferenceEntity> optimize(ReferenceEntity reference);
}

abstract interface class ReferenceSyncProvider {
  Future<void> push(String projectId, List<ReferenceEntity> references);
  Future<List<ReferenceEntity>> pull(String projectId);
}

abstract interface class GPUReferenceFitter {
  Future<ReferenceEntity> fit(ReferenceRecipe recipe);
}
