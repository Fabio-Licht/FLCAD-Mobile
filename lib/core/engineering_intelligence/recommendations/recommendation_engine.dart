import '../models/intelligence_models.dart';
import '../reasoning/confidence_engine.dart';

class RecommendationEngine {
  const RecommendationEngine();
  List<EngineeringRecommendation> generate(
    ProjectKnowledgeSnapshot snapshot,
    EngineeringScore score,
  ) {
    final confidence = const ConfidenceEngine().calculate(snapshot),
        affectedFeatures = [
          for (var i = 0; i < snapshot.features.clamp(0, 3); i++) 'feature-$i',
        ],
        affectedReferences = [
          for (var i = 0; i < snapshot.references.clamp(0, 3); i++)
            'reference-$i',
        ];
    return [
      for (final type in RecommendationType.values)
        EngineeringRecommendation(
          type: type,
          title: _title(type),
          confidence: confidence,
          explanation:
              'Consultative analysis based on the current immutable project snapshot',
          technicalReason: _reason(type, snapshot, score),
          advantages: const ['Explainable', 'Non-destructive', 'Project-local'],
          disadvantages: const ['Requires user evaluation'],
          alternatives: _alternatives(type),
          expectedImprovement: (100 - score.overall).clamp(0, 100).toDouble(),
          affectedFeatures: affectedFeatures,
          affectedReferences: affectedReferences,
          affectedRegions: snapshot.criticalRegions,
        ),
    ];
  }

  String _title(RecommendationType type) => switch (type) {
    RecommendationType.nextOperation => 'Next modeling operation',
    RecommendationType.bestDatum => 'Best datum',
    RecommendationType.bestAlignment => 'Best alignment',
    RecommendationType.bestSketch => 'Best sketch strategy',
    RecommendationType.extrudeVsRevolve => 'Extrude versus Revolve',
    RecommendationType.sweepVsLoft => 'Sweep versus Loft',
    RecommendationType.criticalRegions => 'Prioritize critical regions',
    RecommendationType.modelingStrategy => 'Modeling strategy',
    RecommendationType.idealSequence => 'Ideal feature sequence',
    RecommendationType.simplification => 'Model simplification',
    RecommendationType.rebuildRisk => 'Rebuild risk',
    RecommendationType.fragileDependencies => 'Fragile dependencies',
    RecommendationType.dimensionalImprovement => 'Dimensional improvement',
    RecommendationType.machiningPreparation => 'Machining preparation',
    RecommendationType.inspectionPreparation => 'Inspection preparation',
  };
  String _reason(
    RecommendationType type,
    ProjectKnowledgeSnapshot snapshot,
    EngineeringScore score,
  ) =>
      '${type.name}: score ${score.overall.toStringAsFixed(1)}, ${snapshot.dependencyRisks} dependency risks and ${snapshot.criticalRegions.length} critical regions';
  List<String> _alternatives(RecommendationType type) => switch (type) {
    RecommendationType.extrudeVsRevolve => const ['Extrude', 'Revolve'],
    RecommendationType.sweepVsLoft => const ['Sweep', 'Loft'],
    RecommendationType.bestAlignment => const [
      'Plane + Axis',
      'Best Fit',
      'ICP',
    ],
    _ => const ['Keep current strategy', 'Review manually'],
  };
}
