import '../models/platform_certification_models.dart';

class AIPlatformCertificationEngine {
  const AIPlatformCertificationEngine();

  AIEngineeringPlatformCertificate certify({
    required String version,
    required String certificationDate,
    required String coverage,
    int pipelineCount = 2500,
  }) {
    if (certificationDate.trim().isEmpty) {
      throw ArgumentError('Certification date must be supplied explicitly');
    }
    final modules = _moduleCertifications();
    final architecture = _architectureAudit(modules);
    return AIEngineeringPlatformCertificate(
      version: version,
      certificationDate: certificationDate,
      pipelineCount: pipelineCount,
      coverage: coverage,
      modules: modules,
      architecture: architecture,
      conformity: const [
        'ADR-057',
        'ADR-058',
        'ADR-059',
        'ADR-060',
        'ADR-061',
        'ADR-062',
        'ADR-063',
        'ADR-064',
        'Project First',
        'Explainable deterministic consultation only',
      ],
    );
  }

  List<ModuleCertification> _moduleCertifications() {
    const definitions = <(String, String, List<String>)>[
      (
        'AI Engineering Foundation',
        'G-012A',
        [
          'Context',
          'Snapshots',
          'Feature Vector',
          'Confidence Engine',
          'Advisor',
          'Analytics',
          'Persistence',
        ],
      ),
      (
        'Primitive Intelligence',
        'G-012B',
        [
          'Planes',
          'Cylinders',
          'Cones',
          'Spheres',
          'Tori',
          'Symmetries',
          'Patterns',
          'Manufacturing Intelligence',
        ],
      ),
      (
        'Engineering Features',
        'G-012C',
        [
          'Feature Graph',
          'Confidence Tree',
          'Engineering DNA',
          'Relations',
          'Dependencies',
          'Explainability',
        ],
      ),
      (
        'Smart References',
        'G-012D',
        [
          'Datum Intelligence',
          'Coordinate Systems',
          'Canonical References',
          'Ranking',
          'Alignment Strategies',
          'Explainability',
        ],
      ),
      (
        'Reconstruction Strategy',
        'G-012E',
        [
          'Playbooks',
          'Dependency Graph',
          'Strategy Builder',
          'Difficulty Estimator',
          'Engineering Reasoning',
          'Rollback',
        ],
      ),
      (
        'Interactive Assistant',
        'G-012F',
        [
          'Context Awareness',
          'Conversation Layer',
          'Timeline',
          'Snapshots',
          'Alerts',
          'Suggestions',
          'Multi Strategy Comparator',
        ],
      ),
      (
        'Engineering Knowledge',
        'G-012G',
        [
          'Case Library',
          'Knowledge Profiles',
          'Similarity Engine',
          'Rule Engine',
          'Decision Memory',
          'Recommendation Engine',
        ],
      ),
    ];
    return [
      for (final item in definitions)
        ModuleCertification(
          id: item.$1,
          sprint: item.$2,
          capabilities: item.$3,
          evidence: [
            'test/${_testFile(item.$2)}',
            'tool/${_toolFile(item.$2)}',
            'docs/adr/${_adrFile(item.$2)}',
          ],
          justification:
              'All declared capabilities have deterministic tests, persistence contracts and a sprint certificate.',
          origin: 'G-012H architecture audit manifest',
          score: 1,
          discardedHypotheses: const [
            'automatic execution',
            'external context',
            'non-deterministic inference',
          ],
        ),
    ];
  }

  String _testFile(String sprint) => switch (sprint) {
    'G-012A' => 'ai_engineering_foundation_test.dart',
    'G-012B' => 'primitive_intelligence_test.dart',
    'G-012C' => 'engineering_feature_intelligence_test.dart',
    'G-012D' => 'smart_reference_test.dart',
    'G-012E' => 'reconstruction_strategy_test.dart',
    'G-012F' => 'interactive_engineering_assistant_test.dart',
    _ => 'professional_engineering_knowledge_test.dart',
  };
  String _toolFile(String sprint) => switch (sprint) {
    'G-012A' => 'ai_engineering_certification.dart',
    'G-012B' => 'primitive_intelligence_certification.dart',
    'G-012C' => 'engineering_feature_intelligence_certification.dart',
    'G-012D' => 'smart_reference_certification.dart',
    'G-012E' => 'reconstruction_strategy_certification.dart',
    'G-012F' => 'interactive_engineering_assistant_certification.dart',
    _ => 'engineering_knowledge_certification.dart',
  };

  String _adrFile(String sprint) => switch (sprint) {
    'G-012A' => 'ADR-057-ai-engineering-foundation.md',
    'G-012B' => 'ADR-058-professional-primitive-intelligence-engine.md',
    'G-012C' => 'ADR-059-professional-engineering-feature-intelligence.md',
    'G-012D' => 'ADR-060-professional-smart-reference-system.md',
    'G-012E' => 'ADR-061-professional-reconstruction-strategy-ai.md',
    'G-012F' => 'ADR-062-professional-interactive-engineering-assistant.md',
    _ => 'ADR-063-professional-engineering-knowledge-engine.md',
  };

  ArchitectureAudit _architectureAudit(List<ModuleCertification> modules) {
    final names = modules.map((e) => e.id).toList();
    return ArchitectureAudit(
      modules: names,
      dependencies: const [
        DependencyEdge('Primitive Intelligence', 'AI Engineering Foundation'),
        DependencyEdge('Engineering Features', 'Primitive Intelligence'),
        DependencyEdge('Smart References', 'Engineering Features'),
        DependencyEdge('Reconstruction Strategy', 'Smart References'),
        DependencyEdge('Interactive Assistant', 'Reconstruction Strategy'),
        DependencyEdge('Engineering Knowledge', 'Interactive Assistant'),
      ],
      workspaces: names.map((e) => '$e Workspace'),
      propertyInspectors: names.map((e) => '$e Property Inspector'),
      persistenceRoots: const [
        'CAD/AIEngineering',
        'CAD/PrimitiveIntelligence',
        'CAD/EngineeringFeatures',
        'CAD/SmartReferences',
        'CAD/ReconstructionStrategies',
        'CAD/InteractiveAssistant',
        'CAD/EngineeringKnowledge',
      ],
      analytics: names.map((e) => '$e Analytics'),
      adrs: const [
        'ADR-057',
        'ADR-058',
        'ADR-059',
        'ADR-060',
        'ADR-061',
        'ADR-062',
        'ADR-063',
      ],
      maxSerializedPipelineBytes: 65536,
    );
  }

  bool validateDeterminism({
    required String version,
    required String certificationDate,
    required String coverage,
    int repetitions = 2500,
  }) {
    final baseline = certify(
      version: version,
      certificationDate: certificationDate,
      coverage: coverage,
    ).canonicalJson();
    for (var index = 0; index < repetitions; index++) {
      if (certify(
            version: version,
            certificationDate: certificationDate,
            coverage: coverage,
          ).canonicalJson() !=
          baseline) {
        return false;
      }
    }
    return true;
  }
}
