import '../models/ai_engineering_models.dart';

abstract interface class AIEngineeringIntegration {
  void onSessionChanged(IntentSession session);
}

class AIEngineeringModuleGraph {
  AIEngineeringModuleGraph(Iterable<String> modules)
    : modules = Set.unmodifiable(modules);
  final Set<String> modules;
  static const officialModules = {
    'Recognition',
    'Topology',
    'Continuity',
    'Surface Operations',
    'Morph',
    'Extend',
    'Reduce',
    'Fair',
    'Boundary',
    'Manufacturing',
    'Advanced Surface',
    'AI Engineering',
    'Live Reconstruction',
  };
  bool get isComplete => modules.containsAll(officialModules);
  List<String> get workflow => const [
    'Recognition',
    'Topology',
    'Continuity',
    'Surface Operations',
    'Morph',
    'Manufacturing',
    'AI Engineering',
    'Live Reconstruction',
  ];
}

class OfficialAIEngineeringIntegration implements AIEngineeringIntegration {
  OfficialAIEngineeringIntegration({
    required this.project,
    required this.workspace,
    required this.propertyInspector,
    required this.analytics,
    required this.advisor,
    AIEngineeringModuleGraph? graph,
  }) : graph =
           graph ??
           AIEngineeringModuleGraph(AIEngineeringModuleGraph.officialModules);
  final Map<String, dynamic> project,
      workspace,
      propertyInspector,
      analytics,
      advisor;
  final AIEngineeringModuleGraph graph;
  @override
  void onSessionChanged(IntentSession session) {
    project['aiEngineeringSession'] = session.toJson();
    workspace['aiEngineering'] = true;
    workspace['timeline'] = session.history.toJson();
    propertyInspector['aiEngineeringSessionId'] = session.id;
    analytics['hypothesisCount'] = session.intent.candidates.length;
    advisor['consultativeOnly'] = true;
    advisor['automaticActions'] = false;
  }
}
