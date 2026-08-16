import 'dart:io';

import 'package:flcad_mobile/core/engineering/context/engineering_context.dart';
import 'package:flcad_mobile/core/engineering_knowledge/engineering_knowledge.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/reverse_intelligence/brain/reverse_brain.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

class _Plugin implements EngineeringKnowledgePlugin {
  @override
  String get id => 'test';
  @override
  String get version => '1';
  @override
  KnowledgeLibrary knowledge() => KnowledgeLibrary([
    const KnowledgeConcept(
      id: 'plugin.feature',
      name: 'Plugin feature',
      kind: 'feature',
      description: 'test',
      attributes: {},
      provenance: KnowledgeProvenance('test', '1'),
    ),
  ]);
  @override
  List<EngineeringRule> rules() => const [];
}

void main() {
  test('ontology models hierarchy and relationships', () {
    final ontology = CoreEngineeringOntology.create();
    expect(ontology.isA('hole', 'feature'), isTrue);
    expect(
      ontology.ancestors('bearingSeat'),
      containsAll(['housing', 'feature']),
    );
    expect(
      () => ontology.relate(const OntologyEdge('missing', 'hole', 'invalid')),
      throwsStateError,
    );
  });
  test(
    'feature, manufacturing, inspection and material libraries are structured',
    () {
      final features = FeatureKnowledgeLibrary.create(),
          manufacturing = ManufacturingKnowledgeLibrary.create(),
          inspection = InspectionKnowledgeLibrary.create(),
          materials = MaterialKnowledgeLibrary.create();
      expect(
        features.find('housing.bearing')!.attributes['requires'],
        contains('toleranceClass'),
      );
      expect(
        manufacturing.find('process.cnc')!.attributes['considerations'],
        contains('minimumInternalRadius'),
      );
      expect(
        inspection.find('inspection.position')!.kind,
        'inspectionCharacteristic',
      );
      expect(
        materials.find('material.titanium')!.attributes['compatibleProcesses'],
        contains('process.cnc'),
      );
    },
  );
  test('rules only infer when all evidence conditions are satisfied', () {
    final engine = CoreEngineeringRules.create(),
        positive = EngineeringCase(
          projectId: 'p',
          entityId: 'e',
          facts: const {'feature.hole': true, 'feature.thread': true},
          probabilities: const {},
        ),
        negative = EngineeringCase(
          projectId: 'p',
          entityId: 'e',
          facts: const {'feature.hole': true},
          probabilities: const {},
        );
    expect(
      engine.infer(positive).map((i) => i.conclusion),
      contains('requirement.nominalDiameter'),
    );
    expect(
      engine.infer(negative).map((i) => i.conclusion),
      isNot(contains('requirement.nominalDiameter')),
    );
  });
  test('patterns and heuristics infer flange search from symmetric holes', () {
    const value = EngineeringCase(
      projectId: 'p',
      entityId: 'e',
      facts: {'hole.count': 4, 'symmetry.planar': true},
      probabilities: {},
    );
    expect(
      EngineeringPatternLibrary.foundation().match(value).single.conclusion,
      'feature.flange',
    );
    expect(
      HeuristicEngine().apply(value).single.conclusion,
      'search.feature.flange',
    );
  });
  test('reasoner explains bearing seat from engineering evidence', () {
    final value = EngineeringCase(
          projectId: 'p',
          entityId: 'e',
          facts: const {
            'feature.fillet': true,
            'inspection.tolerance': true,
            'alignment.mainAxis': true,
          },
          probabilities: const {'surface.cylinder': .91},
        ),
        result = EngineeringReasoner().reason(value),
        seat = result.best('feature.bearingSeat');
    expect(seat, isNotNull);
    expect(seat!.confidence, closeTo(.92 * .91, 1e-12));
    expect(result.explanation, contains('feature.bearingSeat'));
    expect(seat.ruleIds, contains('rule.bearingSeat'));
  });
  test('dataset codec imports versioned extensible knowledge', () {
    const source =
        '{"id":"company","version":"1.2","concepts":[{"id":"fixture.custom","name":"Custom fixture","kind":"feature","attributes":{"function":"locate"},"tags":["fixture"]}]}';
    final dataset = const KnowledgeDatasetCodec().decode(source),
        api = EngineeringKnowledgeApi();
    api.load(dataset);
    expect(api.query('fixture').single.provenance.version, '1.2');
    expect(
      const KnowledgeDatasetCodec().encode(dataset),
      contains('fixture.custom'),
    );
  });
  test('learning records explicit user feedback', () async {
    final store = InMemoryKnowledgeLearningStore(),
        engine = KnowledgeLearningEngine(store),
        now = DateTime.now();
    await engine.learn(
      EngineeringLearningSample(
        'p',
        'e',
        'feature.flange',
        true,
        now,
        const {},
      ),
    );
    await engine.learn(
      EngineeringLearningSample(
        'p',
        'e2',
        'feature.flange',
        false,
        now,
        const {},
      ),
    );
    expect(await engine.observedAcceptance('feature.flange'), .5);
  });
  test('runtime performs reasoning in isolate', () async {
    final result = await const KnowledgeRuntime().reason(
      const EngineeringCase(
        projectId: 'p',
        entityId: 'e',
        facts: {'feature.hole': true, 'feature.thread': true},
        probabilities: {},
      ),
    );
    expect(result.best('requirement.nominalDiameter'), isNotNull);
  });
  test('Engineering Context and FEL expose Engineering DNA', () {
    final context = EngineeringContext.standard('p'),
        registry = createNativeCommandRegistry(Directory.systemTemp);
    expect(
      context.services.get<EngineeringKnowledgeApi>(),
      isA<EngineeringKnowledgeApi>(),
    );
    for (final name in [
      'LOAD KNOWLEDGE',
      'QUERY KNOWLEDGE',
      'EXPLAIN FEATURE',
      'EXPLAIN MANUFACTURING',
      'SUGGEST FEATURE',
      'SUGGEST PROCESS',
      'REASON',
      'INFER',
      'LEARN ENGINEERING',
      'EXPORT KNOWLEDGE',
    ]) {
      expect(registry.find(name), isNotNull, reason: name);
    }
  });
  test('standards are references without fabricated normative limits', () {
    final standards = StandardsRegistry.foundation();
    expect(standards.find('AP242')!.topic, contains('STEP'));
    expect(standards.items.every((s) => s.edition == null), isTrue);
  });
  test('plugins extend and unload knowledge without recompilation', () {
    final registry = KnowledgePluginRegistry()..register(_Plugin());
    expect(registry.aggregate().find('plugin.feature'), isNotNull);
    expect(registry.unregister('test'), isNotNull);
    expect(registry.plugins, isEmpty);
  });
  test('advisor and relationship graph preserve traceability', () {
    final result = EngineeringReasoner().reason(
          const EngineeringCase(
            projectId: 'p',
            entityId: 'e',
            facts: {'feature.hole': true, 'feature.thread': true},
            probabilities: {},
          ),
        ),
        library = FeatureKnowledgeLibrary.create(),
        advice = const EngineeringAdvisor().advise(result, library);
    expect(advice, isNotEmpty);
    final ontology = CoreEngineeringOntology.create(),
        graph = CoreEngineeringRelationships.create(ontology.concepts);
    expect(graph.path('flange', 'hole'), ['flange', 'hole']);
  });
  test('AREI integration updates Engineering Core infrastructure', () async {
    final context = EngineeringContext.standard('p'),
        mesh = MeshTopology(
          id: 'mesh',
          vertices: const [
            Vec3(0, 0, 0),
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1),
          ],
          triangles: const [
            Triangle(0, 2, 1),
            Triangle(0, 1, 3),
            Triangle(0, 3, 2),
            Triangle(1, 2, 3),
          ],
        ),
        twin = const ReverseBrain().reason('p', mesh).twin,
        integration = EngineeringKnowledgeIntegration(
          context.services.get<EngineeringKnowledgeApi>(),
        );
    final result = await integration.inferArei(
      context,
      twin,
      observedFacts: const {'feature.pocket': true},
    );
    expect(result.inferences, isNotEmpty);
    expect(
      context.history.query(domain: 'engineering_knowledge'),
      hasLength(1),
    );
    expect(context.events.query(domain: 'engineering_knowledge'), hasLength(1));
    expect(context.graph.impact('mesh'), isNotEmpty);
  });
}
