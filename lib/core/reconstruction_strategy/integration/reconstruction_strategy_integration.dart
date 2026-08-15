import '../models/reconstruction_strategy_models.dart';

abstract interface class ReconstructionStrategyIntegration {
  void onSessionChanged(ReconstructionStrategySession session);
}

class ReconstructionStrategyModuleGraph {
  ReconstructionStrategyModuleGraph(Iterable<String> modules)
    : modules = Set.unmodifiable(modules);
  final Set<String> modules;
  static const officialModules = {
    'AI Engineering Foundation',
    'Primitive Intelligence',
    'Engineering Feature Intelligence',
    'Smart Reference System',
    'Recognition',
    'Topology',
    'Reconstruction Strategy AI',
    'Manufacturing',
    'Live Reconstruction',
  };
  bool get isComplete => modules.containsAll(officialModules);
}

class OfficialReconstructionStrategyIntegration
    implements ReconstructionStrategyIntegration {
  OfficialReconstructionStrategyIntegration({
    required this.project,
    required this.aiFoundation,
    required this.primitiveIntelligence,
    required this.featureIntelligence,
    required this.smartReferences,
    required this.workspace,
    required this.propertyInspector,
    required this.analytics,
    ReconstructionStrategyModuleGraph? graph,
  }) : graph =
           graph ??
           ReconstructionStrategyModuleGraph(
             ReconstructionStrategyModuleGraph.officialModules,
           );
  final Map<String, dynamic> project,
      aiFoundation,
      primitiveIntelligence,
      featureIntelligence,
      smartReferences,
      workspace,
      propertyInspector,
      analytics;
  final ReconstructionStrategyModuleGraph graph;
  @override
  void onSessionChanged(ReconstructionStrategySession session) {
    project['reconstructionStrategies'] = session.toJson();
    aiFoundation['engineeringPlaybook'] = session.playbook.toJson();
    primitiveIntelligence['reconstructionStrategySessionId'] = session.id;
    featureIntelligence['reconstructionStrategySessionId'] = session.id;
    smartReferences['reconstructionStrategySessionId'] = session.id;
    workspace['reconstructionStrategy'] = true;
    propertyInspector['reconstructionStrategySessionId'] = session.id;
    analytics['strategiesGenerated'] = session.strategies.length;
  }
}
