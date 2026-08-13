import '../models/intelligence_models.dart';

abstract interface class CloudReverseIntelligence {
  Future<List<ProbabilityScore>> infer(
    String projectId,
    MeshObservation observation,
  );
}
