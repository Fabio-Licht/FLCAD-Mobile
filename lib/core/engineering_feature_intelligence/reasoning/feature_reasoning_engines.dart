import '../../primitive_intelligence/models/primitive_intelligence_models.dart';
import '../models/engineering_feature_models.dart';

class ManufacturingContextIntelligence {
  const ManufacturingContextIntelligence();
  String infer(EngineeringFeatureType type) => switch (type) {
    EngineeringFeatureType.draftRegion ||
    EngineeringFeatureType.moldPartingCandidate => 'molding',
    EngineeringFeatureType.fillet ||
    EngineeringFeatureType.chamfer ||
    EngineeringFeatureType.machiningFeature => 'machining',
    EngineeringFeatureType.rectangularPocket ||
    EngineeringFeatureType.circularPocket ||
    EngineeringFeatureType.organicPocket ||
    EngineeringFeatureType.slot ||
    EngineeringFeatureType.keyway => 'milling',
    EngineeringFeatureType.bearingSeat ||
    EngineeringFeatureType.shaft ||
    EngineeringFeatureType.revolution => 'turning',
    EngineeringFeatureType.cylindricalBoss ||
    EngineeringFeatureType.prismaticBoss ||
    EngineeringFeatureType.datumFeature => 'reference establishment',
    EngineeringFeatureType.stampingRegion => 'stamping',
    EngineeringFeatureType.electrodeCandidate => 'electrode manufacturing',
    _ => 'feature-dependent manufacturing review',
  };
}

class ReconstructionStrategyEngine {
  const ReconstructionStrategyEngine();
  ReconstructionStrategy build(EngineeringFeatureType type) {
    final steps = switch (type) {
      EngineeringFeatureType.bearingSeat => const [
        'Base Plane',
        'Main Axis',
        'Cylinder',
        'Shoulder',
        'Fillets',
      ],
      EngineeringFeatureType.flange => const [
        'Base Plane',
        'Center Axis',
        'Flange Profile',
        'Circular Pattern',
        'Fillets',
      ],
      EngineeringFeatureType.simpleHole ||
      EngineeringFeatureType.throughHole ||
      EngineeringFeatureType.blindHole ||
      EngineeringFeatureType.steppedHole ||
      EngineeringFeatureType.countersunkHole ||
      EngineeringFeatureType.threadedHole => const [
        'Reference Plane',
        'Hole Axis',
        'Canonical Diameter',
        'Depth or Through Condition',
      ],
      EngineeringFeatureType.extrusion => const [
        'Profile Plane',
        'Canonical Profile',
        'Extrusion Direction',
        'Extent',
      ],
      EngineeringFeatureType.revolution || EngineeringFeatureType.shaft =>
        const ['Main Axis', 'Canonical Profile', 'Revolution', 'Transitions'],
      _ => ['Reference Context', 'Canonical ${type.name}', 'Continuity Review'],
    };
    return ReconstructionStrategy(
      featureType: type,
      steps: steps,
      justification:
          'Ordered consultative seed for ${type.name}; no step is executed.',
    );
  }
}

class CanonicalFeatureEngine {
  const CanonicalFeatureEngine();
  CanonicalFeatureSuggestion suggest(
    EngineeringFeatureType type,
    PrimitiveHypothesis primitive,
  ) => CanonicalFeatureSuggestion(
    measuredFeature: primitive.id,
    canonicalFeature: type.name,
    justification:
        'Canonical ${type.name} is the selected library candidate for the measured primitive subgraph.',
    deviation: primitive.primitive.measures['canonicalDeviation'] ?? 0,
    confidence: primitive.scores.confidence,
  );
}

class EngineeringDnaBuilder {
  const EngineeringDnaBuilder();
  EngineeringDna build(List<EngineeringFeatureHypothesis> hypotheses) {
    final ordered = [...hypotheses]
      ..sort((a, b) {
        final score = b.scores.overallConfidence.compareTo(
          a.scores.overallConfidence,
        );
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    final relationships =
        ordered
            .expand((e) => e.graph.edges.map((edge) => edge.relationship.name))
            .toSet()
            .toList()
          ..sort();
    final symmetries =
        ordered
            .expand(
              (e) => e.graph.nodes
                  .where((n) => n.kind == 'symmetry')
                  .map((n) => n.referenceId),
            )
            .toSet()
            .toList()
          ..sort();
    final manufacturing = ordered.isEmpty
        ? 'undetermined'
        : ManufacturingContextIntelligence().infer(ordered.first.type);
    return EngineeringDna(
      predominantFeatures: ordered.map((e) => e.type.name),
      geometricRelationships: relationships.where(
        (e) =>
            e != FeatureRelationshipType.dependency.name &&
            e != FeatureRelationshipType.sequence.name,
      ),
      topologicalRelationships: relationships.where(
        (e) =>
            e == FeatureRelationshipType.dependency.name ||
            e == FeatureRelationshipType.sequence.name,
      ),
      symmetries: symmetries,
      probableManufacturingStrategy: manufacturing,
      probableReconstructionStrategy: ordered
          .expand((e) => e.strategy.steps)
          .toSet(),
      geometricComplexity: ordered
          .fold<int>(0, (sum, e) => sum + e.graph.nodes.length)
          .toDouble(),
      functionalComplexity: ordered
          .map((e) => e.function)
          .toSet()
          .length
          .toDouble(),
    );
  }
}
