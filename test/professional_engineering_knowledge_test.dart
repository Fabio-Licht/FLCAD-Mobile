import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/engineering_knowledge/engineering_knowledge.dart';
import 'package:flutter_test/flutter_test.dart';

ProfessionalEngineeringCase fixture([String id = 'case-1']) =>
    ProfessionalEngineeringCase(
      id: id,
      name: 'Bearing Housing 024',
      partType: 'Bearing Housing',
      profileId: 'profile-generalTools',
      domain: KnowledgeDomain.generalTools,
      userId: 'fabio',
      logicalDate: '2026-L01',
      origin: 'project:user-approved',
      signature: CaseSignature(
        dna: const ['rotational', 'machined'],
        features: const ['flange', 'bore'],
        topology: const ['coaxial'],
        symmetries: const ['axial'],
        relations: const ['plane-cylinder'],
        complexity: .4,
        strategy: 'productivity',
      ),
      primitiveGraph: const {
        'nodes': ['plane', 'cylinder'],
      },
      featureGraph: const {
        'nodes': ['flange', 'bore'],
      },
      smartReferences: const {'base': 'plane-1'},
      playbook: const {
        'steps': ['base', 'axis', 'flange'],
      },
      selectedStrategy: 'productivity',
      userChanges: const ['fillets-last'],
      finalResult: 'approved',
    );

void main() {
  group('Professional Engineering Knowledge Engine', () {
    test('profiles are independent and complete', () {
      final profiles = EngineeringKnowledgeEngine.defaultProfiles;
      expect(profiles.length, 9);
      expect(
        profiles.map((e) => e.domain).toSet(),
        KnowledgeDomain.values.toSet(),
      );
      expect(profiles.every((e) => e.origin.isNotEmpty), isTrue);
    });

    test('case, decision memory, rule editing and rollback are versioned', () {
      final engine = EngineeringKnowledgeEngine()..registerCase(fixture());
      engine.recordDecision(
        const KnowledgeDecision(
          id: 'd1',
          kind: KnowledgeDecisionKind.strategyAccepted,
          targetId: 'productivity',
          userJustification: 'Validated result',
          origin: 'user:fabio',
          sequence: 1,
          version: 1,
        ),
      );
      engine.addRule(
        EngineeringKnowledgeRule(
          id: 'r1',
          profileId: 'profile-generalTools',
          description: 'Largest plane and cylinder',
          requiredEvidence: const ['largest-plane', 'largest-cylinder'],
          suggestion: 'Suggest base plane',
          origin: 'user:fabio',
        ),
      );
      final beforeEdit = engine.state.revision;
      engine.editRule(
        'r1',
        suggestion: 'Suggest base plane then principal axis',
      );
      expect(engine.state.rules.single.version, 2);
      expect(
        engine.evaluateRules('profile-generalTools', [
          'largest-plane',
          'largest-cylinder',
        ]),
        hasLength(1),
      );
      expect(engine.rollback(beforeEdit).rules.single.version, 1);
    });

    test('similarity, recommendations and reuse are fully consultive', () {
      final engine = EngineeringKnowledgeEngine()..registerCase(fixture());
      final scores = engine.findSimilar(fixture().signature);
      expect(scores.single.percentage, 100);
      expect(
        scores.single.toJson().keys,
        containsAll([
          'dnaScore',
          'featureScore',
          'topologyScore',
          'symmetryScore',
          'relationScore',
          'complexityScore',
          'strategyScore',
        ]),
      );
      expect(
        engine
            .recommendFromCase(
              'case-1',
              'Use productivity',
              'Approved equal case',
            )
            .caseId,
        'case-1',
      );
      final reuse = engine.proposeReuse(
        'case-1',
        StrategyReuseScope.selectedSteps,
        stepIds: ['base'],
      );
      expect(reuse.toJson(), containsPair('applied', false));
      expect(
        () => engine.recommendFromCase('missing', 'x', 'x'),
        throwsStateError,
      );
    });

    test('explorer, workspace, analytics and integration are exposed', () {
      final engine = EngineeringKnowledgeEngine()..registerCase(fixture());
      expect(
        engine.search(const KnowledgeQuery(feature: 'flange', userId: 'fabio')),
        hasLength(1),
      );
      final workspace = EngineeringKnowledgeWorkspace(engine.state);
      expect(workspace.panels, contains('Engineering Knowledge'));
      expect(workspace.propertyInspector['Panel'], 'Engineering Knowledge');
      expect(
        EngineeringKnowledgeAnalytics(engine.state).toJson()['internalTimers'],
        isFalse,
      );
      expect(EngineeringKnowledgeModuleGraph.isAcyclic, isTrue);
    });

    test('Project First persistence creates all six stores', () async {
      final directory = await Directory.systemTemp.createTemp('g012g_');
      addTearDown(() => directory.delete(recursive: true));
      final engine = EngineeringKnowledgeEngine()..registerCase(fixture());
      await EngineeringKnowledgeRepository(directory).persist(engine.state);
      for (final path in EngineeringKnowledgeRepository.paths) {
        expect(
          File(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}${Platform.pathSeparator}knowledge.json',
          ).existsSync(),
          isTrue,
        );
      }
    });

    test('2,000 pipelines are deterministic, auditable and mutation-free', () {
      String pipeline(int index) {
        final engine = EngineeringKnowledgeEngine()
          ..registerCase(fixture('case-$index'));
        engine.findSimilar(fixture('query-$index').signature);
        engine.recommendFromCase(
          'case-$index',
          'Reuse productivity',
          'Same deterministic signature',
        );
        engine.proposeReuse('case-$index', StrategyReuseScope.completePlaybook);
        return jsonEncode(engine.state.toJson());
      }

      for (var i = 0; i < 2000; i++) {
        final first = pipeline(i), second = pipeline(i);
        expect(first, second);
        expect(first, contains('"geometryModified":false'));
        expect(first, contains('"automaticBehaviorChanges":false'));
      }
    });

    test('certification passes', () {
      final report = const EngineeringKnowledgeCertification().run();
      expect(report.certified, isTrue, reason: report.toJson().toString());
    });
  });
}
