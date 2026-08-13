import '../models/workflow_models.dart';

class WorkflowAdvisor {
  const WorkflowAdvisor();
  List<WorkflowRecommendation> evaluate(ProfessionalWorkflowState state) {
    final stage = state.currentStage;
    if (stage == null) return const [];
    final evidence = <WorkflowEvidence>[];
    var confidence = .8;
    String title, action, why, impact;
    switch (stage) {
      case ProfessionalWorkflowStage.importStl:
        title = 'Importe a malha de origem';
        action = 'Selecionar STL';
        why =
            'A análise geométrica precisa de uma malha pertencente ao Projeto.';
        impact = 'Libera avaliação, regiões e planejamento; não cria CAD.';
        evidence.add(
          const WorkflowEvidence(
            id: 'project-open',
            description: 'Projeto ativo e sem malha importada',
            source: 'workflow',
            weight: 1,
          ),
        );
        confidence = 1;
      case ProfessionalWorkflowStage.createReferences:
        title = 'Criar referência sugerida';
        action = 'Revisar referência';
        why = 'Regiões reconhecidas podem estabelecer uma base estável.';
        impact = 'Organiza sketches e superfícies posteriores.';
        evidence.add(
          const WorkflowEvidence(
            id: 'regions-ready',
            description: 'Reconhecimento de regiões concluído',
            source: 'Smart Regions',
            weight: .9,
          ),
        );
      case ProfessionalWorkflowStage.planCad:
        title = 'Revisar plano CAD';
        action = 'Aprovar plano';
        why = 'Referências, sketches e superfícies planejadas estão ordenados.';
        impact = 'Produz somente um plano auditável; nenhum B-Rep será criado.';
        evidence.add(
          const WorkflowEvidence(
            id: 'plans-ready',
            description: 'Dependências de planejamento concluídas',
            source: 'Autonomous Reconstruction',
            weight: .9,
          ),
        );
      default:
        final step = state.steps.firstWhere((value) => value.stage == stage);
        title = step.title;
        action = 'Continuar';
        why = 'É a próxima etapa cujas dependências foram satisfeitas.';
        impact = 'Avança o workflow preservando a ordem de engenharia.';
        evidence.add(
          WorkflowEvidence(
            id: 'dependency-chain',
            description: '${step.requires.length} dependência(s) satisfeita(s)',
            source: 'Guided Workflow',
            weight: .85,
          ),
        );
    }
    return [
      WorkflowRecommendation(
        id: 'recommendation:${stage.name}',
        stage: stage,
        title: title,
        actionLabel: action,
        decision: ExplainableDecision(
          why: why,
          evidence: evidence,
          alternatives: const ['Revisar manualmente', 'Adiar etapa'],
          confidence: confidence,
          impact: impact,
        ),
      ),
    ];
  }
}
