import '../../engineering_decision/api/decision_api.dart';
import '../../engineering_decision/models/decision_models.dart' as ede;
import '../../professional_recognition/models/professional_recognition_models.dart';
import '../graph/reconstruction_graph.dart';
import '../models/reconstruction_intelligence_models.dart';
import '../strategy/strategy_generator.dart';
import '../templates/reconstruction_templates.dart';

class EngineeringReconstructionPlanner {
  EngineeringReconstructionPlanner({DecisionApi? decisions})
    : decisions = decisions ?? DecisionApi();
  final DecisionApi decisions;
  final strategies = const EngineeringStrategyGenerator();
  final templates = const ReconstructionTemplateLibrary();

  Future<EngineeringReconstructionPlan> plan(ERIPlanningInput input) async {
    final report = input.recognition,
        candidates = strategies.generate(report),
        selected = candidates.first,
        template = templates.select([
          ...report.manufacturing.map((e) => e.kind),
          ...report.features.map((e) => e.type.name),
        ]),
        generated = _nodes(report, selected, template),
        graph = ERIReconstructionGraph(generated),
        ordered = graph.removeRedundant(),
        affected = input.previous == null
            ? <String>{}
            : _affected(input.previous!, input.changedSourceIds),
        merged = input.previous == null
            ? ordered
            : _merge(input.previous!, ordered, affected),
        now = DateTime.now(),
        normalized = _ready(merged),
        score = _score(report, normalized),
        analytics = _analytics(report, normalized),
        timeline = [
          ...?input.previous?.timeline,
          ERITimelineEntry(
            (input.previous?.timeline.length ?? 0) + 1,
            now,
            input.previous == null ? 'planned' : 'replanned',
            'plan:${report.projectId}',
            'ERI',
            input.previous == null
                ? 'Initial professional plan'
                : 'Incremental replan of ${affected.length} affected nodes',
            (input.previous?.revision ?? 0) + 1,
          ),
        ],
        plan = EngineeringReconstructionPlan(
          id: input.previous?.id ?? 'eri:${report.projectId}',
          projectId: report.projectId,
          revision: (input.previous?.revision ?? 0) + 1,
          nodes: normalized,
          strategies: candidates,
          selectedStrategyId: selected.id,
          score: score,
          timeline: timeline,
          analytics: analytics,
          createdAt: input.previous?.createdAt ?? now,
          updatedAt: now,
          sourceFingerprint: _fingerprint(report),
        );
    await decisions.create(
      ede.DecisionRequest(
        projectId: report.projectId,
        type: ede.EngineeringDecisionType.strategy,
        origin: ede.DecisionOrigin.autonomous,
        title: 'Selecionar estratégia ${selected.name}',
        impact: 'Define somente a ordem do plano ERI.',
        criteria: ede.DecisionCriteria(
          recognitionConfidence: report.averageConfidence,
          meshQuality: report.recognizedCoverage,
          captureCompleteness: report.recognizedCoverage,
          computationalCost: selected.cost,
          reconstructionImpact: score.quality,
          referenceReuse: score.reuse,
          partComplexity: 1 - score.simplicity,
          engineeringIntent: report.functions.isEmpty
              ? 0
              : report.functions.first.probability,
          successHistory: 0,
        ),
        evidence: [
          ede.DecisionEvidence(
            id: 'eri-strategy',
            description: selected.explanation,
            source: 'ERI',
            value: selected.confidence,
          ),
        ],
      ),
    );
    return plan;
  }

  List<ERIPlanNode> _nodes(
    ProfessionalRecognitionReport r,
    ERIStrategy strategy,
    ReconstructionTemplate? template,
  ) {
    final nodes = <ERIPlanNode>[];
    final planes = r.primitives
            .where((p) => p.recognition.winner.type.name == 'plane')
            .toList(),
        cylinders = r.primitives
            .where((p) => p.recognition.winner.type.name == 'cylinder')
            .toList();
    nodes.add(
      ERIPlanNode(
        id: 'reference:base',
        type: ERINodeType.reference,
        level: ReconstructionLevel.references,
        title: 'Plano base',
        dependencies: const [],
        alternatives: const ['Plano secundário', 'Referência pela malha'],
        cost: .1,
        risk: ERIRisk.low,
        confidence: planes.isEmpty
            ? 0.4
            : planes.first.recognition.dna.confidence,
        impact: 'Ancora todas as etapas downstream.',
        priority: 100,
        explanation: planes.isEmpty
            ? 'Plano base precisa de validação manual.'
            : 'Maior plano reconhecido oferece datum estável.',
        sourceIds: planes.isEmpty ? const [] : [planes.first.recognition.id],
      ),
    );
    if (cylinders.isNotEmpty) {
      nodes.add(
        ERIPlanNode(
          id: 'reference:axis',
          type: ERINodeType.reference,
          level: ReconstructionLevel.references,
          title: 'Eixo mestre',
          dependencies: const ['reference:base'],
          alternatives: const ['Eixo secundário'],
          cost: .1,
          risk: ERIRisk.low,
          confidence: cylinders.first.recognition.dna.confidence,
          impact: 'Controla coaxialidade.',
          priority: 95,
          explanation: 'Cilindro dominante deve orientar o eixo mestre.',
          sourceIds: [cylinders.first.recognition.id],
        ),
      );
    }
    nodes.add(
      ERIPlanNode(
        id: 'sketch:primary',
        type: ERINodeType.sketch,
        level: ReconstructionLevel.sketches,
        title: 'Sketch primário',
        dependencies: [cylinders.isEmpty ? 'reference:base' : 'reference:axis'],
        alternatives: const ['Sketch por seção'],
        cost: .25,
        risk: ERIRisk.medium,
        confidence: r.averageConfidence,
        impact: 'Define perfil principal.',
        priority: 75,
        explanation: 'Sketch segue referências para evitar instabilidade.',
        sourceIds: r.features.expand((e) => e.primitiveIds).toSet().toList(),
      ),
    );
    for (final primitive in r.primitives.where(
      (p) => p.recognition.winner.type.name == 'torus',
    )) {
      nodes.add(
        ERIPlanNode(
          id: 'surface:${primitive.recognition.id}',
          type: ERINodeType.surface,
          level: ReconstructionLevel.surfaces,
          title:
              'Plano de superfície ${primitive.recognition.winner.type.name}',
          dependencies: const ['sketch:primary'],
          alternatives: const ['Loft', 'Patch', 'Sweep'],
          cost: .55,
          risk: ERIRisk.medium,
          confidence: primitive.recognition.dna.confidence,
          impact: 'Representa região curva sem executá-la.',
          priority: 55,
          explanation:
              'Superfície complexa é planejada após o perfil principal.',
          sourceIds: [primitive.recognition.id],
        ),
      );
    }
    for (final feature in r.features) {
      nodes.add(
        ERIPlanNode(
          id: 'feature:${feature.id}',
          type: ERINodeType.feature,
          level: ReconstructionLevel.features,
          title: 'Planejar ${feature.type.name}',
          dependencies: const ['sketch:primary'],
          alternatives: const ['Adiar feature', 'Modelagem híbrida'],
          cost: .4,
          risk: feature.confidence < .6 ? ERIRisk.high : ERIRisk.medium,
          confidence: feature.confidence,
          impact: 'Organiza intenção paramétrica.',
          priority: 50 + feature.confidence * 20,
          explanation: feature.explanation,
          sourceIds: [feature.id],
        ),
      );
    }
    final terminal = nodes
        .where(
          (n) => n.type == ERINodeType.feature || n.type == ERINodeType.surface,
        )
        .map((e) => e.id)
        .toList();
    nodes.add(
      ERIPlanNode(
        id: 'milestone:solid',
        type: ERINodeType.solidMilestone,
        level: ReconstructionLevel.solidPlan,
        title: 'Marco de planejamento Solid',
        dependencies: terminal.isEmpty ? const ['sketch:primary'] : terminal,
        alternatives: const ['Manter modelo híbrido'],
        cost: .8,
        risk: ERIRisk.high,
        confidence: .4,
        impact: 'Marca dependências; não cria sólido.',
        priority: 10,
        explanation: 'B-Rep e sólidos não são executados nesta versão.',
        sourceIds: const [],
        status: ERINodeStatus.blocked,
      ),
    );
    if (template != null) {
      nodes.add(
        ERIPlanNode(
          id: 'validation:template',
          type: ERINodeType.validation,
          level: ReconstructionLevel.solidPlan,
          title: 'Validar template ${template.name}',
          dependencies: const ['milestone:solid'],
          alternatives: const ['Revisão manual'],
          cost: .15,
          risk: ERIRisk.low,
          confidence: .7,
          impact: 'Compara plano com prática conhecida.',
          priority: 5,
          explanation: template.guidance,
          sourceIds: [template.id],
        ),
      );
    }
    return nodes;
  }

  Set<String> _affected(
    EngineeringReconstructionPlan plan,
    List<String> changed,
  ) {
    final graph = ERIReconstructionGraph(plan.nodes),
        direct = plan.nodes
            .where((n) => n.sourceIds.any(changed.contains))
            .map((e) => e.id)
            .toSet();
    return {...direct, ...direct.expand(graph.dependents)};
  }

  List<ERIPlanNode> _merge(
    EngineeringReconstructionPlan previous,
    List<ERIPlanNode> fresh,
    Set<String> affected,
  ) {
    final old = {for (final n in previous.nodes) n.id: n};
    return fresh
        .map(
          (n) => !affected.contains(n.id) && old.containsKey(n.id)
              ? old[n.id]!
              : n,
        )
        .toList();
  }

  List<ERIPlanNode> _ready(List<ERIPlanNode> nodes) {
    final ordered = ERIReconstructionGraph(nodes).ordered();
    return [
      for (var i = 0; i < ordered.length; i++)
        ordered[i].status != ERINodeStatus.planned
            ? ordered[i]
            : ordered[i].copyWith(
                status: i == 0 ? ERINodeStatus.ready : ERINodeStatus.planned,
              ),
    ];
  }

  ReconstructionScore _score(
    ProfessionalRecognitionReport r,
    List<ERIPlanNode> n,
  ) => ReconstructionScore(
    simplicity: 1 - (n.length / 30).clamp(0, 1),
    robustness: r.averageConfidence,
    quality: r.recognizedCoverage,
    maintainability: n.isEmpty
        ? 0
        : n.where((e) => e.dependencies.length <= 2).length / n.length,
    manufacturability: r.manufacturing.isEmpty
        ? 0
        : r.manufacturing.first.probability,
    inspectability: r.relations.isEmpty ? 0.4 : 0.75,
    reuse: n.isEmpty
        ? 0
        : n.where((e) => e.type == ERINodeType.reference).length / n.length,
  );
  ReconstructionAnalytics _analytics(
    ProfessionalRecognitionReport r,
    List<ERIPlanNode> n,
  ) => ReconstructionAnalytics(
    steps: n.length,
    estimatedTime: Duration(
      minutes: n.fold<int>(0, (s, e) => s + (e.cost * 20).round()),
    ),
    estimatedSavings: Duration(
      minutes: n.where((e) => e.confidence > .75).length * 2,
    ),
    criticalRegions: r.pendingRegionIds.length,
    bottlenecks: n.where((e) => e.dependencies.length > 3).length,
    dependencies: n.fold<int>(0, (s, e) => s + e.dependencies.length),
    averageConfidence: n.isEmpty
        ? 0
        : n.map((e) => e.confidence).reduce((a, b) => a + b) / n.length,
  );
  String _fingerprint(ProfessionalRecognitionReport r) =>
      r.primitives.map((e) => e.recognition.dna.geometricSignature).join('|');
}
