import '../models/workflow_models.dart';

class GuidedWorkflowEngine {
  const GuidedWorkflowEngine();
  static const _titles = <ProfessionalWorkflowStage, String>{
    ProfessionalWorkflowStage.openProject: 'Abrir Projeto',
    ProfessionalWorkflowStage.importStl: 'Importar STL',
    ProfessionalWorkflowStage.analyzeMesh: 'Analisar Malha',
    ProfessionalWorkflowStage.assessQuality: 'Avaliar Qualidade',
    ProfessionalWorkflowStage.recognizeRegions: 'Reconhecer Regiões',
    ProfessionalWorkflowStage.createReferences: 'Criar Referências',
    ProfessionalWorkflowStage.createSketches: 'Criar Sketches',
    ProfessionalWorkflowStage.planSurfaces: 'Planejar Superfícies',
    ProfessionalWorkflowStage.planFeatures: 'Planejar Features',
    ProfessionalWorkflowStage.planCad: 'Planejar CAD',
    ProfessionalWorkflowStage.export: 'Exportação',
  };

  ProfessionalWorkflowState create(String projectId) {
    final stages = ProfessionalWorkflowStage.values;
    final steps = <ProfessionalWorkflowStep>[];
    for (var index = 0; index < stages.length; index++) {
      final stage = stages[index];
      steps.add(
        ProfessionalWorkflowStep(
          stage: stage,
          title: _titles[stage]!,
          status: index == 0
              ? ProfessionalStageStatus.completed
              : index == 1
              ? ProfessionalStageStatus.ready
              : ProfessionalStageStatus.locked,
          order: index,
          requires: index == 0 ? const [] : [stages[index - 1]],
          progress: index == 0 ? 1 : 0,
          blockReason: stage == ProfessionalWorkflowStage.export
              ? 'Exportação CAD real depende de kernel futuro.'
              : null,
        ),
      );
    }
    final now = DateTime.now();
    return ProfessionalWorkflowState(
      projectId: projectId,
      steps: steps,
      artifacts: [
        ProfessionalArtifact(
          id: projectId,
          projectId: projectId,
          name: 'Projeto',
          kind: ProfessionalArtifactKind.project,
          origin: 'Project Manifest',
          dna: 'project:$projectId',
          confidence: 1,
        ),
      ],
      timeline: [
        EngineeringTimelineEntry(
          sequence: 1,
          timestamp: now,
          type: 'project',
          title: 'Projeto aberto',
          description: 'Sessão profissional iniciada.',
        ),
      ],
      recommendations: const [],
      inspector: const InspectorSnapshot(),
      dashboard: const WorkflowDashboardSnapshot(
        progress: 1 / 11,
        coverage: 0,
        regionCount: 0,
        hypothesisCount: 0,
        strategy: 'Aguardando análise',
        aiStatus: 'Pronta',
        plannedOperations: 0,
      ),
      updatedAt: now,
    );
  }

  ProfessionalWorkflowState start(
    ProfessionalWorkflowState state,
    ProfessionalWorkflowStage stage,
  ) {
    final target = state.steps.firstWhere((step) => step.stage == stage);
    if (target.status != ProfessionalStageStatus.ready) {
      throw StateError('Etapa ${target.title} não está pronta.');
    }
    return _replace(
      state,
      target.copyWith(status: ProfessionalStageStatus.active),
    );
  }

  ProfessionalWorkflowState complete(
    ProfessionalWorkflowState state,
    ProfessionalWorkflowStage stage, {
    ProfessionalArtifact? artifact,
  }) {
    final target = state.steps.firstWhere((step) => step.stage == stage);
    if (target.status != ProfessionalStageStatus.active &&
        target.status != ProfessionalStageStatus.ready) {
      throw StateError('Etapa ${target.title} não pode ser concluída.');
    }
    var steps = state.steps
        .map(
          (step) => step.stage == stage
              ? target.copyWith(
                  status: ProfessionalStageStatus.completed,
                  progress: 1,
                )
              : step,
        )
        .toList();
    final nextIndex = target.order + 1;
    if (nextIndex < steps.length) {
      final next = steps[nextIndex];
      steps[nextIndex] = next.copyWith(status: ProfessionalStageStatus.ready);
    }
    final timeline = [
      ...state.timeline,
      EngineeringTimelineEntry(
        sequence: state.timeline.length + 1,
        timestamp: DateTime.now(),
        type: 'workflow',
        title: '${target.title} concluída',
        description: artifact == null
            ? 'Etapa confirmada.'
            : '${artifact.name} registrado.',
        artifactId: artifact?.id,
      ),
    ];
    final artifacts = [...state.artifacts, ?artifact];
    final progress =
        steps.fold<double>(0, (sum, step) => sum + step.progress) /
        steps.length;
    return state.copyWith(
      steps: steps,
      artifacts: artifacts,
      timeline: timeline,
      dashboard: WorkflowDashboardSnapshot(
        progress: progress,
        coverage: state.inspector.coverage,
        regionCount: state.dashboard.regionCount,
        hypothesisCount: state.dashboard.hypothesisCount,
        strategy: state.dashboard.strategy,
        aiStatus: 'Pronta',
        plannedOperations: artifacts
            .where(
              (a) => a.kind.index >= ProfessionalArtifactKind.reference.index,
            )
            .length,
      ),
    );
  }

  ProfessionalWorkflowState _replace(
    ProfessionalWorkflowState state,
    ProfessionalWorkflowStep replacement,
  ) => state.copyWith(
    steps: state.steps
        .map((step) => step.stage == replacement.stage ? replacement : step)
        .toList(),
  );
}
