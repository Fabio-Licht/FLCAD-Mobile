import '../models/intelligence_models.dart';

abstract interface class ReverseIntelligencePlugin {
  String get id;
  String get version;
  Future<List<ProbabilityScore>> infer(MeshObservation observation);
}
