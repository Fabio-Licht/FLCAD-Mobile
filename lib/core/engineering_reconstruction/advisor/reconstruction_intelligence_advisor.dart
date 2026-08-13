import '../models/reconstruction_intelligence_models.dart';

class ERIAdvice {
  const ERIAdvice(
    this.nodeId,
    this.message,
    this.why,
    this.alternatives,
    this.confidence,
  );
  final String nodeId, message, why;
  final List<String> alternatives;
  final double confidence;
}

class ReconstructionIntelligenceAdvisor {
  const ReconstructionIntelligenceAdvisor();
  ERIAdvice? next(EngineeringReconstructionPlan plan) {
    final node = plan.nextStep;
    if (node == null) return null;
    final message = switch (node.type) {
      ERINodeType.reference => 'Comece pela referência de maior impacto.',
      ERINodeType.sketch => 'Crie o sketch após estabilizar as referências.',
      ERINodeType.surface => 'Planeje esta superfície; detalhes podem esperar.',
      ERINodeType.feature => 'Planeje a feature reconhecida.',
      ERINodeType.solidMilestone =>
        'Revise o marco Solid; execução geométrica não está disponível.',
      ERINodeType.validation => 'Valide o plano contra evidências.',
    };
    return ERIAdvice(
      node.id,
      message,
      node.explanation,
      node.alternatives,
      node.confidence,
    );
  }
}
