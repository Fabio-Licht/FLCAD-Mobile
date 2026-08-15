import '../models/smart_reference_models.dart';

abstract interface class SmartReferenceIntegration {
  void onSessionChanged(SmartReferenceSession session);
}

class SmartReferenceModuleGraph {
  SmartReferenceModuleGraph(Iterable<String> modules)
    : modules = Set.unmodifiable(modules);
  final Set<String> modules;
  static const officialModules = {
    'AI Engineering Foundation',
    'Primitive Intelligence',
    'Engineering Feature Intelligence',
    'Recognition',
    'Topology',
    'Continuity',
    'Smart Reference System',
    'Surface Operations',
    'Manufacturing',
    'Live Reconstruction',
  };
  bool get isComplete => modules.containsAll(officialModules);
}

class OfficialSmartReferenceIntegration implements SmartReferenceIntegration {
  OfficialSmartReferenceIntegration({
    required this.project,
    required this.aiFoundation,
    required this.primitiveIntelligence,
    required this.featureIntelligence,
    required this.workspace,
    required this.propertyInspector,
    required this.analytics,
    SmartReferenceModuleGraph? graph,
  }) : graph =
           graph ??
           SmartReferenceModuleGraph(SmartReferenceModuleGraph.officialModules);
  final Map<String, dynamic> project,
      aiFoundation,
      primitiveIntelligence,
      featureIntelligence,
      workspace,
      propertyInspector,
      analytics;
  final SmartReferenceModuleGraph graph;
  @override
  void onSessionChanged(SmartReferenceSession session) {
    project['smartReferences'] = session.toJson();
    aiFoundation['referenceCandidates'] = session.candidates
        .map((e) => e.toJson())
        .toList();
    primitiveIntelligence['smartReferenceSessionId'] = session.id;
    featureIntelligence['smartReferenceSessionId'] = session.id;
    workspace['smartReferences'] = true;
    propertyInspector['smartReferenceSessionId'] = session.id;
    analytics['referencesSuggested'] = session.candidates.length;
  }
}
