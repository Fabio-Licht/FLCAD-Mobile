import 'dart:convert';
import 'dart:io';

import 'engineering_knowledge_models.dart';

class EngineeringKnowledgeAnalytics {
  const EngineeringKnowledgeAnalytics(this.state);
  final EngineeringKnowledgeState state;
  Map<String, dynamic> toJson() => {
    'registeredCases': state.cases.length,
    'reuseProposals': state.reuseProposals.length,
    'similaritiesCalculated': state.similarities.length,
    'strategiesReused': state.decisions
        .where((e) => e.kind == KnowledgeDecisionKind.strategyAccepted)
        .length,
    'rulesApplied': state.rules.where((e) => e.enabled).length,
    'internalTimers': false,
  };
}

class EngineeringKnowledgeWorkspace {
  const EngineeringKnowledgeWorkspace(this.state);
  final EngineeringKnowledgeState state;
  List<String> get panels => const [
    'Library',
    'Similar Cases',
    'Recommendations',
    'Profiles',
    'Statistics',
    'Rules',
    'Engineering Knowledge',
  ];
  Map<String, dynamic> get propertyInspector => {
    'Panel': 'Engineering Knowledge',
    'Similar Cases': state.similarities.map((e) => e.toJson()).toList(),
    'Active Profile': state.profiles.firstOrNull?.toJson(),
    'Recommended Strategy': state.recommendations.firstOrNull?.toJson(),
    'History': state.decisions.map((e) => e.toJson()).toList(),
  };
}

class EngineeringKnowledgeRepository {
  EngineeringKnowledgeRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError('Project First requires an absolute directory');
    }
  }
  final Directory projectDirectory;
  static const paths = [
    'CAD/EngineeringKnowledge',
    'CAD/EngineeringCases',
    'CAD/KnowledgeProfiles',
    'CAD/KnowledgeRules',
    'CAD/SimilarityDatabase',
    'CAD/StrategyHistory',
  ];
  String _path(String relative) =>
      '${projectDirectory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(EngineeringKnowledgeState state) async {
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    Future<void> write(String path, Object data) => File(
      '${_path(path)}${Platform.pathSeparator}knowledge.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await write('CAD/EngineeringKnowledge', {
      'state': state.toJson(),
      'analytics': EngineeringKnowledgeAnalytics(state).toJson(),
    });
    await write(
      'CAD/EngineeringCases',
      state.cases.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/KnowledgeProfiles',
      state.profiles.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/KnowledgeRules',
      state.rules.map((e) => e.toJson()).toList(),
    );
    await write(
      'CAD/SimilarityDatabase',
      state.similarities.map((e) => e.toJson()).toList(),
    );
    await write('CAD/StrategyHistory', {
      'decisions': state.decisions.map((e) => e.toJson()).toList(),
      'reuse': state.reuseProposals.map((e) => e.toJson()).toList(),
    });
  }
}

class EngineeringKnowledgeModuleGraph {
  static const dependencies = {
    'EngineeringKnowledge': [
      'AIEngineeringFoundation',
      'PrimitiveIntelligence',
      'EngineeringFeatureIntelligence',
      'SmartReferences',
      'ReconstructionStrategy',
      'InteractiveAssistant',
      'Manufacturing',
    ],
  };
  static bool get isAcyclic => dependencies.values.every(
    (values) => !values.contains('EngineeringKnowledge'),
  );
}
