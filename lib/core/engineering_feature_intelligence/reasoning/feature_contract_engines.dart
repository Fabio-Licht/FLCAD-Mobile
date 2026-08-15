import '../models/engineering_feature_models.dart';

class FunctionalRecognition {
  const FunctionalRecognition();
  FeatureFunction recognize({
    required EngineeringFeatureType type,
    int? declaredCode,
  }) {
    if (declaredCode != null &&
        declaredCode >= 0 &&
        declaredCode < FeatureFunction.values.length) {
      return FeatureFunction.values[declaredCode];
    }
    return switch (type) {
      EngineeringFeatureType.bearingSeat ||
      EngineeringFeatureType.flange ||
      EngineeringFeatureType.housing ||
      EngineeringFeatureType.shaft ||
      EngineeringFeatureType.keyway => FeatureFunction.assembly,
      EngineeringFeatureType.rib ||
      EngineeringFeatureType.cylindricalBoss ||
      EngineeringFeatureType.prismaticBoss => FeatureFunction.structural,
      EngineeringFeatureType.datumFeature => FeatureFunction.reference,
      EngineeringFeatureType.machiningFeature ||
      EngineeringFeatureType.draftRegion ||
      EngineeringFeatureType.moldPartingCandidate ||
      EngineeringFeatureType.stampingRegion ||
      EngineeringFeatureType.electrodeCandidate =>
        FeatureFunction.manufacturing,
      _ => FeatureFunction.functional,
    };
  }
}

class FeatureRelationshipEngine {
  const FeatureRelationshipEngine();
  List<FeatureGraphEdge> analyze(FeatureGraph graph) =>
      List.unmodifiable(graph.edges);
}

class FeatureRankingEngine {
  const FeatureRankingEngine();
  List<EngineeringFeatureHypothesis> rank(
    Iterable<EngineeringFeatureHypothesis> hypotheses,
  ) => List.unmodifiable(
    hypotheses.toList()..sort((a, b) {
      final score = b.scores.overallConfidence.compareTo(
        a.scores.overallConfidence,
      );
      return score != 0 ? score : a.id.compareTo(b.id);
    }),
  );
}
