import '../models/intelligence_models.dart';

class ReverseEngineeringPlanner {
  const ReverseEngineeringPlanner();
  ReconstructionPlan plan(
    String meshId,
    List<ProbabilityScore> classifications,
    List<EngineeringHypothesis> hypotheses,
  ) {
    final dominant = classifications.first,
        steps = <ReconstructionStep>[
          const ReconstructionStep(
            1,
            'detectRegions',
            'Establish measurable geometric partitions',
            .6,
          ),
          const ReconstructionStep(
            2,
            'createReferences',
            'Anchor subsequent operations to stable references',
            .7,
          ),
        ];
    if (dominant.label == 'prismatic') {
      steps.insert(
        1,
        const ReconstructionStep(
          2,
          'fitPlanes',
          'Prismatic evidence favors planar references',
          .65,
        ),
      );
    }
    if (dominant.label == 'turned') {
      steps.insert(
        1,
        const ReconstructionStep(
          2,
          'fitAxesAndCylinders',
          'Revolution evidence favors axial references',
          .65,
        ),
      );
    }
    steps.addAll([
      ReconstructionStep(
        steps.length + 1,
        'buildSketches',
        'Convert validated references into editable intent',
        .7,
      ),
      ReconstructionStep(
        steps.length + 2,
        'proposeSurfaces',
        'Prepare surface hypotheses without final reconstruction',
        .75,
      ),
      ReconstructionStep(
        steps.length + 3,
        'validate',
        'Compare every proposal against observed evidence',
        .8,
      ),
    ]);
    return ReconstructionPlan(
      '$meshId:plan',
      List.unmodifiable(steps),
      'Dominant classification ${dominant.label} at ${(dominant.probability * 100).toStringAsFixed(1)}%; ${hypotheses.length} supported hypotheses.',
    );
  }
}
