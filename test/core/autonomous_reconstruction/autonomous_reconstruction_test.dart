import 'dart:io';

import 'package:flcad_mobile/core/autonomous_reconstruction/autonomous_reconstruction.dart';
import 'package:flcad_mobile/core/engineering/context/engineering_context.dart';
import 'package:flcad_mobile/core/engineering_cognition/orchestrator/cognition_orchestrator.dart';
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
  late CognitionResult cognition;
  setUp(
    () => cognition = EngineeringCognitionOrchestrator().analyze(
      const ReverseBrain().reason('project', mesh).twin,
    ),
  );
  test('master planner builds ordered Project First dependency workflow', () {
    final workflow = const ReconstructionMasterPlanner().build(
          ReconstructionPlanInput(cognition.snapshot),
        ),
        graph = ReconstructionDependencyGraph(workflow.stages),
        order = graph.topologicalOrder();
    expect(workflow.stages.first.type, ReconstructionStageType.project);
    expect(workflow.stages[1].type, ReconstructionStageType.mesh);
    expect(order, workflow.stages.map((s) => s.id).toList());
    expect(workflow.stages.last.type, ReconstructionStageType.validation);
    expect(
      const ReconstructionWorkflowValidator().validate(workflow).valid,
      isTrue,
    );
  });
  test(
    'every decision has confidence evidence risk alternatives and impact',
    () {
      final workflow = const ReconstructionMasterPlanner().build(
        ReconstructionPlanInput(cognition.snapshot),
      );
      for (final stage in workflow.stages) {
        expect(stage.decision.confidence, inInclusiveRange(0, 1));
        expect(stage.decision.evidence, isNotEmpty);
        expect(stage.decision.impact, isNotEmpty);
        expect(stage.decision.explanation, isNotEmpty);
        expect(stage.decision.risk, isA<ReconstructionRisk>());
      }
    },
  );
  test('scheduler enforces dependencies and exposes timeline', () {
    final scheduler = ReconstructionScheduler(
          const ReconstructionMasterPlanner().build(
            ReconstructionPlanInput(cognition.snapshot),
          ),
        ),
        first = scheduler.executable.single;
    expect(first.type, ReconstructionStageType.project);
    scheduler.start(first.id);
    scheduler.complete(first.id);
    expect(scheduler.executable.single.type, ReconstructionStageType.mesh);
    expect(
      scheduler.timeline.entries.map((e) => e.status),
      containsAll([
        ReconstructionStageStatus.running,
        ReconstructionStageStatus.completed,
        ReconstructionStageStatus.ready,
      ]),
    );
  });
  test('scheduler supports pause resume cancellation and blocking', () {
    final scheduler = ReconstructionScheduler(
          const ReconstructionMasterPlanner().build(
            ReconstructionPlanInput(cognition.snapshot),
          ),
        ),
        first = scheduler.executable.single;
    scheduler.start(first.id);
    scheduler.pause();
    expect(scheduler.executable, isEmpty);
    scheduler.resume();
    expect(scheduler.executable.single.id, first.id);
    scheduler.cancel(first.id);
    expect(
      scheduler.workflow.stages
          .where((s) => s.dependencies.contains(first.id))
          .every((s) => s.status == ReconstructionStageStatus.blocked),
      isTrue,
    );
  });
  test('strategy engine selects highest utility candidate', () {
    const engine = AutonomousStrategyEngine();
    final candidates = engine.candidates(cognition.snapshot),
        selected = engine.select(cognition.snapshot);
    expect(selected.id, candidates.first.id);
    expect(candidates, hasLength(3));
  });
  test('advisor prepares progress next step and explanation DTO', () {
    final api = AutonomousReconstructionApi(),
        workflow = api.build(cognition.snapshot),
        state = api.advisor(workflow.id);
    expect(state.progress, 0);
    expect(state.nextStep, isNotNull);
    expect(state.confidence, greaterThan(0));
    expect(state.explanation, isNotEmpty);
  });
  test(
    'interactive rebuild increments revision and preserves workflow identity',
    () {
      final orchestrator = AutonomousReconstructionOrchestrator(),
          first = orchestrator.build(cognition.snapshot),
          second = orchestrator.rebuild(
            cognition.snapshot,
            reason: 'user corrected feature',
          );
      expect(second.id, first.id);
      expect(second.revision, 2);
      expect(second.updatedAt.isBefore(first.createdAt), isFalse);
    },
  );
  test('API refuses to simulate CAD stage execution', () {
    final api = AutonomousReconstructionApi(),
        workflow = api.build(cognition.snapshot),
        stage = workflow.stages.firstWhere(
          (s) => s.type == ReconstructionStageType.surface,
        );
    expect(
      () => api.executeStage(workflow.id, stage.id),
      throwsUnsupportedError,
    );
  });
  test(
    'learning records user changes without mutating prior decisions',
    () async {
      final store = InMemoryReconstructionLearningStore(),
          learning = AutonomousReconstructionLearning(store),
          now = DateTime.now();
      await learning.learn(
        ReconstructionFeedback('p', 'w', 'stage', 'plan', 'accepted', now),
      );
      await learning.learn(
        ReconstructionFeedback('p', 'w', 'stage', 'plan', 'rejected', now),
      );
      expect(await learning.preference('stage'), 0);
    },
  );
  test('runtime and serialization preserve portable plan', () async {
    final workflow = await const AutonomousReconstructionRuntime().plan(
          cognition.snapshot,
        ),
        json = const WorkflowSerialization().encode(workflow);
    expect(json, contains('flcad.autonomous-reconstruction'));
    expect(json, contains('dependencies'));
    expect(workflow.stages, isNotEmpty);
  });
  test(
    'Engineering Core integration persists history graph and event',
    () async {
      final context = EngineeringContext.standard('project'),
          api = context.services.get<AutonomousReconstructionApi>(),
          workflow = await AutonomousReconstructionIntegration(
            api,
          ).build(context, cognition.snapshot);
      expect(
        context.history.query(domain: 'autonomous_reconstruction'),
        hasLength(1),
      );
      expect(
        context.events.query(domain: 'autonomous_reconstruction'),
        hasLength(1),
      );
      expect(context.graph.impact(workflow.stages.first.id), isNotEmpty);
    },
  );
  test('FEL exposes autonomous reconstruction vocabulary', () {
    final registry = createNativeCommandRegistry(Directory.systemTemp);
    for (final name in [
      'BUILD RECONSTRUCTION',
      'PLAN RECONSTRUCTION',
      'NEXT STEP',
      'SHOW PLAN',
      'EXPLAIN PLAN',
      'UPDATE PLAN',
      'EXECUTE STAGE',
      'PAUSE PLAN',
      'RESUME PLAN',
      'REBUILD PLAN',
    ]) {
      expect(registry.find(name), isNotNull, reason: name);
    }
  });
}
