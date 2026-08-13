import '../models/cognition_models.dart';

class CognitionCardData {
  const CognitionCardData(
    this.regionId,
    this.feature,
    this.process,
    this.function,
    this.confidence,
    this.strategy,
    this.explanation,
  );
  final String regionId, feature, process, function, strategy, explanation;
  final double confidence;
}

class CognitionAdvisor {
  const CognitionAdvisor();
  CognitionCardData? forRegion(String regionId, CognitionSnapshot snapshot) {
    final features =
        snapshot.features.where((f) => f.regionIds.contains(regionId)).toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    if (features.isEmpty) return null;
    final feature = features.first,
        manufacturing = snapshot.manufacturing
            .where((m) => m.featureId == feature.id)
            .toList(),
        intents = snapshot.intents
            .where((i) => i.featureIds.contains(feature.id))
            .toList(),
        strategy = snapshot.reconstruction
            .where((s) => s.sourceIds.contains(regionId))
            .toList();
    return CognitionCardData(
      regionId,
      feature.kind,
      manufacturing.isEmpty ? 'undetermined' : manufacturing.first.process,
      intents.isEmpty ? 'undetermined' : intents.first.function,
      feature.confidence,
      strategy.isEmpty ? 'review' : strategy.first.recommendation,
      feature.explanation,
    );
  }
}
