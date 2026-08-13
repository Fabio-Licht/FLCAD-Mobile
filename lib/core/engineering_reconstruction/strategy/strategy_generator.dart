import '../../professional_recognition/models/professional_recognition_models.dart';
import '../models/reconstruction_intelligence_models.dart';

class EngineeringStrategyGenerator {
  const EngineeringStrategyGenerator();
  List<ERIStrategy> generate(ProfessionalRecognitionReport report) {
    final confidence = report.averageConfidence,
        freeform = report.primitives
            .where(
              (p) => const [
                'torus',
                'freeform',
              ].contains(p.recognition.winner.type.name),
            )
            .length,
        featureShare = report.features.isEmpty
            ? 0.0
            : (report.features.length / (report.features.length + freeform + 1))
                  .clamp(0, 1);
    final values = [
      ERIStrategy(
        id: 'reference-parametric',
        name: 'Referências e features',
        nodeKinds: const ['Plano', 'Eixo', 'Sketch', 'Features'],
        confidence: confidence * .9,
        cost: .45,
        risk: confidence > .75 ? ERIRisk.low : ERIRisk.medium,
        explanation: 'Referências estáveis reduzem retrabalho downstream.',
        score: confidence * .9 + .25,
      ),
      ERIStrategy(
        id: 'surface-hybrid',
        name: 'Superfícies híbridas',
        nodeKinds: const ['Plano', 'Superfícies', 'Loft/Patch'],
        confidence: confidence * .7 + freeform * .05,
        cost: .7,
        risk: ERIRisk.medium,
        explanation: 'Adequada quando superfícies dominam a evidência.',
        score: confidence * .65 + .1,
      ),
      ERIStrategy(
        id: 'mesh-patch',
        name: 'Mesh híbrida e patches',
        nodeKinds: const ['Mesh híbrida', 'Patch'],
        confidence: confidence * .55,
        cost: .85,
        risk: ERIRisk.high,
        explanation: 'Conserva regiões sem parametrização confiável.',
        score: confidence * .5,
      ),
    ];
    values.sort(
      (a, b) => (b.score + featureShare * .05).compareTo(
        a.score + featureShare * .05,
      ),
    );
    return values;
  }
}
