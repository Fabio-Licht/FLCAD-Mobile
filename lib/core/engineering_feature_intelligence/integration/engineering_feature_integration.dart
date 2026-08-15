import '../models/engineering_feature_models.dart';

abstract interface class EngineeringFeatureIntegration {
  void onSessionChanged(EngineeringFeatureSession session);
}

class EngineeringFeatureModuleGraph {
  EngineeringFeatureModuleGraph(Iterable<String> modules)
    : modules = Set.unmodifiable(modules);
  final Set<String> modules;
  static const officialModules = {
    'Recognition',
    'Primitive Intelligence',
    'AI Engineering Foundation',
    'Topology',
    'Continuity',
    'Engineering Feature Intelligence',
    'Manufacturing',
    'Surface Operations',
    'Live Reconstruction',
  };
  bool get isComplete => modules.containsAll(officialModules);
}

class OfficialEngineeringFeatureIntegration
    implements EngineeringFeatureIntegration {
  OfficialEngineeringFeatureIntegration({
    required this.project,
    required this.primitiveIntelligence,
    required this.aiFoundation,
    required this.workspace,
    required this.propertyInspector,
    required this.analytics,
    EngineeringFeatureModuleGraph? graph,
  }) : graph =
           graph ??
           EngineeringFeatureModuleGraph(
             EngineeringFeatureModuleGraph.officialModules,
           );
  final Map<String, dynamic> project,
      primitiveIntelligence,
      aiFoundation,
      workspace,
      propertyInspector,
      analytics;
  final EngineeringFeatureModuleGraph graph;
  @override
  void onSessionChanged(EngineeringFeatureSession session) {
    project['engineeringFeatures'] = session.toJson();
    project['engineeringDna'] = session.dna.toJson();
    primitiveIntelligence['featureSessionId'] = session.id;
    aiFoundation['engineeringFeatureHypotheses'] = session.hypotheses
        .map((e) => e.toJson())
        .toList();
    aiFoundation['engineeringDna'] = session.dna.toJson();
    workspace['engineeringFeatures'] = true;
    propertyInspector['engineeringFeatureSessionId'] = session.id;
    analytics['featureHypotheses'] = session.hypotheses.length;
  }
}
