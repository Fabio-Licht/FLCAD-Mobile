import '../models/intelligence_models.dart';

class ManufacturingIntelligence {
  const ManufacturingIntelligence();
  List<ProbabilityScore> estimate(
    MeshObservation o,
    List<ProbabilityScore> classes,
  ) {
    double p(String label) =>
        classes.firstWhere((c) => c.label == label).probability;
    Evidence evidence(String id, double value) => Evidence(
      id: id,
      description: 'Geometry classification contribution',
      value: value,
      source: 'geometry.classification',
    );
    final closure = o.isWatertight ? 1.0 : .3,
        results = [
          ProbabilityScore(
            'cncMachining',
            (.7 * p('prismatic') + .3 * p('turned')).clamp(0, 1),
            [
              evidence(
                'machinable_geometry',
                mathMax(p('prismatic'), p('turned')),
              ),
            ],
          ),
          ProbabilityScore(
            'casting',
            (.65 * p('cast') + .35 * closure).clamp(0, 1),
            [evidence('cast_geometry', p('cast'))],
          ),
          ProbabilityScore(
            'injectionMolding',
            (.55 * p('cast') + .45 * closure).clamp(0, 1),
            [evidence('closed_cast_geometry', closure)],
          ),
          ProbabilityScore(
            'forging',
            (.5 * p('turned') + .5 * closure).clamp(0, 1),
            [evidence('axial_closed_geometry', closure)],
          ),
          ProbabilityScore(
            'additiveManufacturing',
            (.6 * p('organic') + .4 * (1 - closure)).clamp(0, 1),
            [evidence('complex_or_open_geometry', p('organic'))],
          ),
          ProbabilityScore(
            'sheetMetal',
            (.8 * p('prismatic') + .2 * o.normalCoherence).clamp(0, 1),
            [evidence('planar_geometry', p('prismatic'))],
          ),
        ];
    return results..sort((a, b) => b.probability.compareTo(a.probability));
  }

  double mathMax(double a, double b) => a > b ? a : b;
}
