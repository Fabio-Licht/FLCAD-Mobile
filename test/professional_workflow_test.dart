import 'dart:io';

import 'package:flcad_mobile/core/professional_workflow/advisor/workflow_advisor.dart';
import 'package:flcad_mobile/core/professional_workflow/engine/guided_workflow_engine.dart';
import 'package:flcad_mobile/core/professional_workflow/models/workflow_models.dart';
import 'package:flcad_mobile/core/professional_workflow/runtime/professional_workflow_controller.dart';
import 'package:flcad_mobile/core/professional_workflow/serialization/workflow_session_repository.dart';
import 'package:flcad_mobile/core/professional_workflow/session/engineering_session.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guided workflow knows current stage and enforces dependency order', () {
    const engine = GuidedWorkflowEngine();
    var state = engine.create('project');
    expect(state.currentStage, ProfessionalWorkflowStage.importStl);
    expect(
      () => engine.start(state, ProfessionalWorkflowStage.analyzeMesh),
      throwsStateError,
    );
    state = engine.start(state, ProfessionalWorkflowStage.importStl);
    state = engine.complete(
      state,
      ProfessionalWorkflowStage.importStl,
      artifact: const ProfessionalArtifact(
        id: 'mesh',
        projectId: 'project',
        name: 'source.stl',
        kind: ProfessionalArtifactKind.mesh,
        origin: 'STL import',
        dna: 'mesh:source',
        confidence: 1,
      ),
    );
    expect(state.currentStage, ProfessionalWorkflowStage.analyzeMesh);
    expect(state.artifacts.last.projectId, 'project');
    expect(state.timeline.last.artifactId, 'mesh');
  });

  test(
    'advisor explains why, evidence, alternatives, confidence and impact',
    () {
      final recommendation = const WorkflowAdvisor()
          .evaluate(const GuidedWorkflowEngine().create('project'))
          .single;
      expect(recommendation.stage, ProfessionalWorkflowStage.importStl);
      expect(recommendation.decision.why, isNotEmpty);
      expect(recommendation.decision.evidence, isNotEmpty);
      expect(recommendation.decision.alternatives, isNotEmpty);
      expect(recommendation.decision.confidence, 1);
      expect(recommendation.decision.impact, contains('CAD'));
    },
  );

  test(
    'timeline and dashboard progress follow completed workflow operations',
    () {
      const engine = GuidedWorkflowEngine();
      var state = engine.create('project');
      state = engine.complete(state, ProfessionalWorkflowStage.importStl);
      state = engine.complete(state, ProfessionalWorkflowStage.analyzeMesh);
      expect(state.timeline.map((entry) => entry.sequence), [1, 2, 3]);
      expect(state.dashboard.progress, closeTo(3 / 11, .0001));
      expect(state.currentStage, ProfessionalWorkflowStage.assessQuality);
    },
  );

  test('productivity analytics use recorded decisions and automations', () {
    final started = DateTime(2026, 1, 1);
    final session =
        EngineeringWorkflowSession(id: 's', projectId: 'p', startedAt: started)
          ..record(SessionEventType.decision, 'one', accepted: true)
          ..record(SessionEventType.decision, 'two', accepted: false)
          ..record(SessionEventType.automation, 'auto');
    final value = session.analytics(
      at: started.add(const Duration(minutes: 10)),
    );
    expect(value.elapsed, const Duration(minutes: 10));
    expect(value.automationsUsed, 1);
    expect(value.operationsAvoided, 3);
    expect(value.estimatedTimeSaved, const Duration(minutes: 2));
    expect(value.acceptanceRate, .5);
  });

  test(
    'controller exposes observable workflow state and persists session',
    () async {
      final root = await Directory.systemTemp.createTemp('omega_workflow_');
      addTearDown(() => root.delete(recursive: true));
      final repository = WorkflowSessionRepository(
        storage: LocalStorageService(rootDirectory: root),
      );
      final controller = ProfessionalWorkflowController(
        projectId: 'project',
        sessionRepository: repository,
      );
      final states = <ProfessionalWorkflowState>[];
      final subscription = controller.changes.listen(states.add);
      controller.start(ProfessionalWorkflowStage.importStl);
      controller.complete(ProfessionalWorkflowStage.importStl);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(states, hasLength(2));
      expect(
        controller.state.currentStage,
        ProfessionalWorkflowStage.analyzeMesh,
      );
      final sessions = Directory(
        '${root.path}${Platform.pathSeparator}Jobs${Platform.pathSeparator}project${Platform.pathSeparator}Sessions',
      );
      expect(await sessions.exists(), isTrue);
      expect(await sessions.list().where((entry) => entry is File).length, 1);
      await subscription.cancel();
      await controller.dispose();
    },
  );

  test(
    'inspector updates reconstruction dashboard without geometry execution',
    () {
      final controller = ProfessionalWorkflowController(projectId: 'project');
      controller.updateInspection(
        const InspectorSnapshot(
          meshQuality: .9,
          coverage: .75,
          confidence: .8,
          reconstructionReadiness: .7,
          normalConsistency: .95,
          openRegions: 2,
        ),
      );
      expect(controller.state.dashboard.coverage, .75);
      expect(controller.state.inspector.openRegions, 2);
      controller.dispose();
    },
  );
}
