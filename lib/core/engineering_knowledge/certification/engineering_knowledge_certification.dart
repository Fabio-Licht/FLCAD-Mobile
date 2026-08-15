import 'dart:convert';

import '../professional/engineering_knowledge_engine.dart';
import '../professional/engineering_knowledge_models.dart';
import '../professional/engineering_knowledge_support.dart';

class EngineeringKnowledgeCertificationReport {
  const EngineeringKnowledgeCertificationReport(this.checks);
  final Map<String, bool> checks;
  bool get certified => checks.values.every((e) => e);
  Map<String, dynamic> toJson() => {'certified': certified, 'checks': checks};
}

class EngineeringKnowledgeCertification {
  const EngineeringKnowledgeCertification();
  EngineeringKnowledgeCertificationReport run() {
    EngineeringKnowledgeState execute() {
      final engine = EngineeringKnowledgeEngine();
      engine.registerCase(_case());
      engine.addRule(
        EngineeringKnowledgeRule(
          id: 'rule-base-axis',
          profileId: 'profile-generalTools',
          description: 'Base and axis',
          requiredEvidence: const [
            'largest-plane',
            'largest-cylinder',
            'symmetry',
          ],
          suggestion: 'Suggest base plane',
          origin: 'user:certification',
        ),
      );
      engine.findSimilar(_case().signature);
      engine.recommendFromCase(
        'case-cert',
        'Reuse productivity strategy',
        'Identical audited case',
      );
      engine.proposeReuse('case-cert', StrategyReuseScope.completePlaybook);
      return engine.state;
    }

    final first = execute(), second = execute();
    final serialized = jsonEncode(first.toJson());
    return EngineeringKnowledgeCertificationReport({
      'determinism': serialized == jsonEncode(second.toJson()),
      'similarity': first.similarities.single.percentage == 100,
      'reuseRequiresApproval':
          first.reuseProposals.single.toJson()['applied'] == false,
      'rulesEditableVersioned': first.rules.single.version == 1,
      'casesHaveOrigin': first.cases.every((e) => e.origin.isNotEmpty),
      'persistencePaths': EngineeringKnowledgeRepository.paths.length == 6,
      'noGeometryMutation': first.toJson()['geometryModified'] == false,
      'integrationAcyclic': EngineeringKnowledgeModuleGraph.isAcyclic,
      'recommendationsReferenceCases': first.recommendations.every(
        (r) => first.cases.any((c) => c.id == r.caseId),
      ),
    });
  }

  ProfessionalEngineeringCase _case() => ProfessionalEngineeringCase(
    id: 'case-cert',
    name: 'Bearing Housing 024',
    partType: 'Bearing Housing',
    profileId: 'profile-generalTools',
    domain: KnowledgeDomain.generalTools,
    userId: 'certifier',
    logicalDate: 'L1',
    origin: 'certification-fixture',
    signature: CaseSignature(
      dna: const ['rotational'],
      features: const ['flange'],
      topology: const ['coaxial'],
      symmetries: const ['axial'],
      relations: const ['plane-cylinder'],
      complexity: .4,
      strategy: 'productivity',
    ),
    primitiveGraph: const {'nodes': 2},
    featureGraph: const {'nodes': 1},
    smartReferences: const {'base': 'plane-1'},
    playbook: const {
      'steps': ['base', 'axis'],
    },
    selectedStrategy: 'productivity',
    userChanges: const [],
    finalResult: 'approved',
  );
}
