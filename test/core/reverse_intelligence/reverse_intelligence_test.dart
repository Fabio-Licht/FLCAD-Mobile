import 'dart:io';

import 'dart:math' as math;
import 'package:flcad_mobile/core/engineering/context/engineering_context.dart';
import 'package:flcad_mobile/core/engineering/learning/engineering_learning.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/reverse_intelligence/reverse_intelligence.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

final mesh = MeshTopology(
  id: 'tetra',
  vertices: const [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)],
  triangles: const [
    Triangle(0, 2, 1),
    Triangle(0, 1, 3),
    Triangle(0, 3, 2),
    Triangle(1, 2, 3),
  ],
);
void main() {
  test('observation extracts measurable topology and geometry', () {
    final o = const ObservationEngine().observe(mesh);
    expect(o.surfaceArea, closeTo(1.5 + math.sqrt(3) / 2, 1e-10));
    expect(o.boundaryEdgeCount, 0);
    expect(o.isWatertight, isTrue);
    expect(
      o.evidence.map((e) => e.id),
      containsAll(['surface_area', 'boundary_edges', 'normal_coherence']),
    );
  });
  test('classification and manufacturing probabilities retain evidence', () {
    final o = const ObservationEngine().observe(mesh),
        classes = const GeometryClassificationEngine().classify(o),
        manufacturing = const ManufacturingIntelligence().estimate(o, classes);
    expect(classes, hasLength(4));
    expect(
      classes.every((p) => p.probability >= 0 && p.probability <= 1),
      isTrue,
    );
    expect(classes.first.evidence, isNotEmpty);
    expect(manufacturing.first.evidence, isNotEmpty);
  });
  test(
    'brain produces hypotheses plan strategies validation and explanation',
    () {
      final result = const ReverseBrain().reason('project', mesh);
      expect(result.twin.hypotheses, isNotEmpty);
      expect(result.twin.plan.steps.last.operation, 'validate');
      expect(result.twin.decision.candidates, hasLength(3));
      expect(result.explanation, contains('Evidence:'));
      expect(result.twin.validation.score, inInclusiveRange(0, 1));
    },
  );
  test(
    'orchestrator builds twin graph and publishes lifecycle events',
    () async {
      final orchestrator = ReconstructionOrchestrator(),
          result = await orchestrator.analyze('project', mesh);
      expect(orchestrator.graph.nodes, hasLength(2));
      expect(
        orchestrator.events.query(domain: 'reverse_intelligence'),
        hasLength(2),
      );
      expect(result.twin.projectId, 'project');
    },
  );
  test('runtime executes reasoning in isolate', () async {
    final result = await const ReverseIntelligenceRuntime().analyze(
      'project',
      mesh,
    );
    expect(result.twin.meshId, 'tetra');
  });
  test('learning records correction in memory and Engineering Core', () async {
    final memory = InMemoryEngineeringMemory(),
        platform = EngineeringLearning(),
        records = <EngineeringLearningRecord>[];
    platform.register((record) async => records.add(record));
    final engine = ReverseLearningEngine(memory, platform);
    await engine.learnCorrection(
      projectId: 'p',
      meshSignature: 'signature',
      strategyId: 's',
      correction: 'prefer axis',
    );
    expect(await memory.similar('signature'), hasLength(1));
    expect(records.single.action, 'correction');
  });
  test('Engineering Context and FEL expose AREI integration', () {
    final context = EngineeringContext.standard('p'),
        registry = createNativeCommandRegistry(Directory.systemTemp);
    expect(
      context.services.get<ReverseIntelligenceApi>(),
      isA<ReverseIntelligenceApi>(),
    );
    for (final name in [
      'ANALYZE MESH',
      'CLASSIFY PART',
      'ESTIMATE MANUFACTURING',
      'PLAN RECONSTRUCTION',
      'GENERATE HYPOTHESES',
      'RUN STRATEGIES',
      'SELECT STRATEGY',
      'EXPLAIN DECISION',
      'LEARN CORRECTION',
      'VALIDATE RECONSTRUCTION',
    ]) {
      expect(registry.find(name), isNotNull, reason: name);
    }
  });
  test(
    'Engineering integration updates cache history graph and events',
    () async {
      final context = EngineeringContext.standard('p'),
          api = context.services.get<ReverseIntelligenceApi>(),
          integration = ReverseEngineeringIntegration(api);
      final first = await integration.analyze(context, mesh),
          second = await integration.analyze(context, mesh);
      expect(identical(first, second), isTrue);
      expect(
        context.history.query(domain: 'reverse_intelligence'),
        hasLength(1),
      );
      expect(context.graph.dependencies(first.twin.plan.id), contains(mesh.id));
      expect(context.events.query(type: 'digitalTwinUpdated'), hasLength(1));
    },
  );
  test('serialization preserves evidence-based digital twin', () {
    final result = const ReverseBrain().reason('p', mesh),
        json = const IntelligenceSerialization().snapshot(result.twin);
    expect(json['schema'], 'flcad.arei.snapshot');
    expect((json['observation'] as Map)['evidence'], isNotEmpty);
    expect((json['decision'] as Map)['strategyId'], isNotEmpty);
  });
}
