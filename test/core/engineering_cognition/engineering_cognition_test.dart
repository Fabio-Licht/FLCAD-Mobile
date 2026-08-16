import 'dart:io';

import 'package:flcad_mobile/core/engineering/context/engineering_context.dart';
import 'package:flcad_mobile/core/engineering_cognition/engineering_cognition.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/reverse_intelligence/brain/reverse_brain.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

final mesh = MeshTopology(
  id: 'part',
  vertices: const [Vec3(0, 0, 0), Vec3(2, 0, 0), Vec3(0, 2, 0), Vec3(0, 0, 1)],
  triangles: const [
    Triangle(0, 2, 1),
    Triangle(0, 1, 3),
    Triangle(0, 3, 2),
    Triangle(1, 2, 3),
  ],
);
void main() {
  late ReverseBrainResult arei;
  setUp(() => arei = const ReverseBrain().reason('project', mesh));
  test(
    'automatic recognition creates evidence-based primitives and features',
    () {
      final result = EngineeringCognitionOrchestrator().analyze(arei.twin);
      expect(result.snapshot.primitives, isNotEmpty);
      expect(result.snapshot.features, isNotEmpty);
      final feature = result.snapshot.features.first;
      expect(feature.confidence, inInclusiveRange(0, 1));
      expect(feature.evidence, isNotEmpty);
      expect(feature.provenance, contains('Engineering DNA'));
      expect(feature.discardedAlternatives, isNotEmpty);
    },
  );
  test('intent and part analysis remain probabilistic', () {
    final result = EngineeringCognitionOrchestrator().analyze(arei.twin);
    expect(result.snapshot.intents, isNotEmpty);
    expect(
      result.snapshot.partClassifications,
      contains(predicate<PartClassification>((p) => p.kind == 'hybrid')),
    );
    expect(
      result.snapshot.partClassifications.every(
        (p) => p.probability >= 0 && p.probability <= 1,
      ),
      isTrue,
    );
  });
  test('recommendation order preserves references before geometry', () {
    final snapshot = EngineeringCognitionOrchestrator()
        .analyze(arei.twin)
        .snapshot;
    final orders = snapshot.reconstruction.map((s) => s.order).toList();
    expect(orders, List.generate(orders.length, (i) => i + 1));
    final firstFeature = snapshot.reconstruction.indexWhere(
          (s) => s.kind == SuggestionKind.feature,
        ),
        lastReference = snapshot.reconstruction.lastIndexWhere(
          (s) => s.kind == SuggestionKind.reference,
        );
    expect(firstFeature, greaterThan(lastReference));
  });
  test('manufacturing and inspection avoid fabricated tolerances', () {
    final snapshot = EngineeringCognitionOrchestrator()
        .analyze(arei.twin)
        .snapshot;
    expect(snapshot.manufacturing, isNotEmpty);
    expect(
      snapshot.manufacturing.every(
        (m) => m.expectedToleranceSource.contains('Project'),
      ),
      isTrue,
    );
    expect(
      snapshot.inspection.every((i) => i.reason.contains('design authority')),
      isTrue,
    );
  });
  test('cognition graph connects part, features, functions and processes', () {
    final result = EngineeringCognitionOrchestrator().analyze(arei.twin);
    expect(result.graph.nodes['part']!.kind, 'part');
    expect(
      result.graph.outgoing('part').any((e) => e.relation == 'contains'),
      isTrue,
    );
    expect(result.graph.edges.any((e) => e.relation == 'performs'), isTrue);
    expect(
      result.graph.edges.any((e) => e.relation == 'manufacturedBy'),
      isTrue,
    );
  });
  test('advisor prepares region UI data without coupling widgets', () {
    final snapshot = EngineeringCognitionOrchestrator()
            .analyze(arei.twin)
            .snapshot,
        region = snapshot.features.first.regionIds.first,
        card = const CognitionAdvisor().forRegion(region, snapshot);
    expect(card, isNotNull);
    expect(card!.feature, isNotEmpty);
    expect(card.explanation, contains('Recognized'));
  });
  test('continuous learning records accept correct and delete', () async {
    final store = InMemoryCognitionLearningStore(),
        learning = CognitionLearningEngine(store),
        now = DateTime.now();
    for (final action in ['accepted', 'corrected', 'deleted']) {
      await learning.record(CognitionFeedback('p', 'e', 'hole', action, now));
    }
    expect(await learning.confidenceAdjustment('hole'), closeTo(-.05, 1e-12));
  });
  test('runtime and serialization support portable cognition', () async {
    final result = await const CognitionRuntime().analyze(arei.twin),
        json = const CognitionSerialization().encode(result.snapshot);
    expect(result.snapshot.meshId, 'part');
    expect(json, contains('flcad.engineering-cognition'));
    expect(json, contains('discardedAlternatives'));
  });
  test(
    'Engineering Core integration registers history graph and event',
    () async {
      final context = EngineeringContext.standard('project'),
          api = context.services.get<EngineeringCognitionApi>(),
          integration = EngineeringCognitionIntegration(api),
          result = await integration.analyze(context, arei.twin);
      expect(
        context.history.query(domain: 'engineering_cognition'),
        hasLength(1),
      );
      expect(
        context.events.query(domain: 'engineering_cognition'),
        hasLength(1),
      );
      expect(context.graph.impact('part'), isNotEmpty);
      expect(result.snapshot.features, isNotEmpty);
    },
  );
  test('FEL registers complete cognition vocabulary', () {
    final registry = createNativeCommandRegistry(Directory.systemTemp);
    for (final name in [
      'RECOGNIZE FEATURES',
      'RECOGNIZE PART',
      'RECOGNIZE FUNCTION',
      'SUGGEST REFERENCES',
      'SUGGEST SURFACES',
      'SUGGEST RECONSTRUCTION',
      'EXPLAIN FEATURE',
      'EXPLAIN PART',
      'ANALYZE ENGINEERING',
      'BUILD FEATURE GRAPH',
    ]) {
      expect(registry.find(name), isNotNull, reason: name);
    }
  });
}
