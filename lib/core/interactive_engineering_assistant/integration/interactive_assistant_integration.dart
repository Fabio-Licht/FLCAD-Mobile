import '../models/interactive_assistant_models.dart';

abstract interface class InteractiveAssistantIntegration {
  void onSessionChanged(InteractiveAssistantSession session);
}

class InteractiveAssistantModuleGraph {
  InteractiveAssistantModuleGraph(Iterable<String> modules)
    : modules = Set.unmodifiable(modules);
  final Set<String> modules;
  static const officialModules = {
    'AI Engineering Foundation',
    'Primitive Intelligence',
    'Engineering Feature Intelligence',
    'Smart Reference System',
    'Reconstruction Strategy AI',
    'Recognition',
    'Topology',
    'Interactive Engineering Assistant',
    'Manufacturing',
    'Live Reconstruction',
  };
  bool get isComplete => modules.containsAll(officialModules);
}

class OfficialInteractiveAssistantIntegration
    implements InteractiveAssistantIntegration {
  OfficialInteractiveAssistantIntegration({
    required this.project,
    required this.aiFoundation,
    required this.primitiveIntelligence,
    required this.featureIntelligence,
    required this.smartReferences,
    required this.reconstructionStrategy,
    required this.workspace,
    required this.propertyInspector,
    required this.analytics,
    InteractiveAssistantModuleGraph? graph,
  }) : graph =
           graph ??
           InteractiveAssistantModuleGraph(
             InteractiveAssistantModuleGraph.officialModules,
           );
  final Map<String, dynamic> project,
      aiFoundation,
      primitiveIntelligence,
      featureIntelligence,
      smartReferences,
      reconstructionStrategy,
      workspace,
      propertyInspector,
      analytics;
  final InteractiveAssistantModuleGraph graph;
  @override
  void onSessionChanged(InteractiveAssistantSession session) {
    project['interactiveAssistant'] = session.toJson();
    aiFoundation['assistantContext'] = session.context.toJson();
    primitiveIntelligence['assistantSessionId'] = session.id;
    featureIntelligence['assistantSessionId'] = session.id;
    smartReferences['assistantSessionId'] = session.id;
    reconstructionStrategy['assistantSessionId'] = session.id;
    workspace['interactiveEngineeringAssistant'] = true;
    propertyInspector['interactiveAssistantSessionId'] = session.id;
    analytics['assistantSuggestions'] = session.suggestions.length;
  }
}
