import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/decision_api.dart';
import '../models/decision_models.dart';

class DecisionFELCommand implements FELCommand {
  DecisionFELCommand(this.name, this.action, this.api);
  @override
  final String name;
  final String action;
  final DecisionApi api;
  @override
  List<FELType> get argumentTypes => switch (action) {
    'list' || 'graph' || 'replay' => const [],
    'simulate' ||
    'strategy' ||
    'override' => const [FELType.string, FELType.string],
    _ => const [FELType.string],
  };
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object value;
    switch (action) {
      case 'create':
        value = await api.create(
          DecisionRequest(
            projectId: context.projectId,
            type: EngineeringDecisionType.workflow,
            origin: DecisionOrigin.user,
            title: args.first.value as String,
            impact: 'Decisão criada via FEL.',
            criteria: const DecisionCriteria(
              recognitionConfidence: .5,
              meshQuality: .5,
              captureCompleteness: .5,
              computationalCost: .5,
              reconstructionImpact: .5,
              referenceReuse: .5,
              partComplexity: .5,
              engineeringIntent: .5,
              successHistory: .5,
            ),
            evidence: const [
              DecisionEvidence(
                id: 'fel',
                description: 'Comando explícito do usuário',
                source: 'FEL',
                value: 1,
              ),
            ],
            responsible: 'FEL user',
          ),
        );
      case 'list':
        value = await api.list(context.projectId);
      case 'explain':
        value = api.explain(args.first.value as String);
      case 'simulate':
        value = api.simulate(args[0].value as String, args[1].value as String);
      case 'strategy':
        value = api.simulate(args[0].value as String, args[1].value as String);
      case 'override':
        value = await api.engine.override(
          args[0].value as String,
          context.projectId,
          DecisionStatus.modified,
          actor: 'FEL user',
          reason: args[1].value as String,
        );
      case 'policy':
        final policy = DecisionPolicy.values.firstWhere(
          (p) =>
              p.name.toUpperCase() ==
              (args.first.value as String).toUpperCase(),
        );
        api.engine.applyPolicy(policy);
        value = policy;
      case 'compare':
        value = api.explain(args.first.value as String).alternatives;
      case 'graph':
        value = api.engine.graph.decisions;
      case 'replay':
        value = api.engine.timeline;
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createDecisionFELCommands({DecisionApi? api}) {
  final decisionApi = api ?? DecisionApi();
  return [
    DecisionFELCommand('CREATE DECISION', 'create', decisionApi),
    DecisionFELCommand('LIST DECISIONS', 'list', decisionApi),
    DecisionFELCommand('EXPLAIN DECISION', 'explain', decisionApi),
    DecisionFELCommand('SIMULATE DECISION', 'simulate', decisionApi),
    DecisionFELCommand('SELECT STRATEGY', 'strategy', decisionApi),
    DecisionFELCommand('OVERRIDE DECISION', 'override', decisionApi),
    DecisionFELCommand('APPLY POLICY', 'policy', decisionApi),
    DecisionFELCommand('COMPARE STRATEGIES', 'compare', decisionApi),
    DecisionFELCommand('SHOW DECISION GRAPH', 'graph', decisionApi),
    DecisionFELCommand('REPLAY DECISIONS', 'replay', decisionApi),
  ];
}
