import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/reverse_workflow/analytics/workflow_analytics.dart';
import 'package:flcad_mobile/core/reverse_workflow/api/reverse_workflow_api.dart';
import 'package:flcad_mobile/core/reverse_workflow/commands/fel_workflow_commands.dart';
import 'package:flcad_mobile/core/reverse_workflow/history/workflow_history.dart';
import 'package:flcad_mobile/core/reverse_workflow/history/workflow_timeline.dart';
import 'package:flcad_mobile/core/reverse_workflow/integration/workflow_factory.dart';
import 'package:flcad_mobile/core/reverse_workflow/integration/workflow_studio.dart';
import 'package:flcad_mobile/core/reverse_workflow/models/workflow_models.dart';
import 'package:flcad_mobile/core/reverse_workflow/repository/workflow_repository.dart';
import 'package:flcad_mobile/core/reverse_workflow/runtime/reverse_workflow_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedKernel implements GeometryKernelAPI {
  int calls = 0;
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'unused',
    name: 'Unused kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities.none,
  );
  @override
  Future<KernelHealth> healthCheck() {
    calls++;
    throw StateError('Workflow must not invoke kernel automatically');
  }

  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) {
    calls++;
    throw StateError('Workflow must not create geometry');
  }

  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) {
    calls++;
    throw StateError('Workflow must not validate geometry automatically');
  }

  @override
  Future<void> begin(KernelTransaction transaction) async => calls++;
  @override
  Future<void> commit(KernelTransaction transaction) async => calls++;
  @override
  Future<void> rollback(KernelTransaction transaction) async => calls++;
  @override
  Future<void> unload() async => calls++;
}

void main() {
  late Directory project;
  late _UnusedKernel kernel;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_workflow_');
    kernel = _UnusedKernel();
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  ReverseWorkflowApi make() => ReverseWorkflowFactory().create(
    projectDirectory: project,
    kernel: kernel,
  );

  test('official steps and states are complete', () {
    expect(ReverseWorkflowStepType.values, hasLength(12));
    expect(WorkflowStepState.values, hasLength(10));
    final api = make(), workflow = api.create('project', 'Reverse');
    expect(workflow.steps.map((e) => e.type), ReverseWorkflowStepType.values);
    expect(
      workflow.steps.every((e) => e.state == WorkflowStepState.ready),
      isTrue,
    );
    expect(workflow.progress, 0);
    expect(kernel.calls, 0);
  });

  test('state machine enforces explicit transitions and waiting states', () {
    final api = make(), workflow = api.create('project', 'State Machine');
    api.open(workflow.id);
    api.engine.startCurrentStep(workflow.id);
    api.engine.setCurrentStepState(workflow.id, WorkflowStepState.waitingUser);
    api.engine.setCurrentStepState(workflow.id, WorkflowStepState.running);
    api.engine.completeCurrentStep(
      workflow.id,
      user: 'operator',
      result: 'mesh imported',
      score: 90,
    );
    expect(workflow.currentIndex, 1);
    expect(workflow.steps.first.state, WorkflowStepState.completed);
    expect(
      () => api.engine.machine.transition(
        workflow.steps.first,
        WorkflowStepState.running,
      ),
      throwsStateError,
    );
    expect(kernel.calls, 0);
  });

  test('pause resume save restore replay undo and redo preserve state', () {
    final api = make(), workflow = api.create('project', 'Lifecycle');
    api.open(workflow.id);
    api.engine.startCurrentStep(workflow.id);
    api.pause(workflow.id);
    expect(workflow.currentStep.state, WorkflowStepState.paused);
    api.resume(workflow.id);
    final saved = api.saveState(workflow.id);
    api.engine.completeCurrentStep(
      workflow.id,
      user: 'operator',
      result: 'done',
    );
    expect(workflow.currentIndex, 1);
    expect(api.undoStep(workflow.id), isTrue);
    expect(workflow.currentIndex, 0);
    expect(api.redoStep(workflow.id), isTrue);
    expect(workflow.currentIndex, 1);
    api.restoreState(workflow.id, saved.id);
    expect(workflow.currentIndex, 0);
    api.replay(workflow.id, saved.id);
    expect(workflow.currentStep.state, WorkflowStepState.running);
  });

  test('required steps cannot be skipped and optional steps can', () {
    final api = make(), workflow = api.create('project', 'Skip');
    expect(
      () => api.engine.skipCurrentStep(workflow.id, user: 'operator'),
      throwsStateError,
    );
    for (var i = 0; i < 6; i++) {
      api.engine.completeCurrentStep(
        workflow.id,
        user: 'operator',
        result: 'completed',
      );
    }
    expect(workflow.currentStep.type, ReverseWorkflowStepType.constraintSolve);
    api.engine.skipCurrentStep(workflow.id, user: 'operator');
    expect(workflow.steps[6].state, WorkflowStepState.skipped);
  });

  test(
    'checklist advisor dashboard and engineering status are read-only guidance',
    () {
      final api = make(), workflow = api.create('project', 'Guided');
      api.engine.updateEngineeringStatus(
        workflow.id,
        score: 82,
        health: 76,
        recommendations: const ['recommendation-1'],
      );
      final checklist = api.checklist(workflow.id),
          advice = api.advise(workflow.id);
      expect(checklist, hasLength(8));
      expect(advice.nextStep, ReverseWorkflowStepType.importMesh);
      expect(advice.pending, hasLength(12));
      expect(advice.critical, contains(ReverseWorkflowStepType.alignment));
      expect(workflow.engineeringScore, 82);
      expect(workflow.projectHealth, 76);
      expect(workflow.recommendationIds, ['recommendation-1']);
      expect(workflow.currentIndex, 0);
      expect(kernel.calls, 0);
    },
  );

  test('1000 workflows checklists advisors snapshots and timeline updates', () {
    final api = make();
    for (var i = 0; i < 1000; i++) {
      final workflow = api.create('project-$i', 'Workflow $i');
      api.open(workflow.id);
      api.engine.completeCurrentStep(
        workflow.id,
        user: 'operator',
        result: 'import-$i',
        score: 80,
        gains: 1,
      );
      api.checklist(workflow.id);
      api.advise(workflow.id);
      api.saveState(workflow.id);
    }
    expect(api.workflows, hasLength(1000));
    expect(api.workflows.map((e) => e.id).toSet(), hasLength(1000));
    expect(api.engine.analytics.workflows, 1000);
    expect(api.engine.analytics.checklistUpdates, 1000);
    expect(api.engine.analytics.advisorUpdates, 1000);
    expect(api.engine.analytics.snapshots, 1000);
    expect(api.engine.analytics.timelineUpdates, 1000);
    expect(api.engine.timeline.entries, hasLength(1000));
    expect(kernel.calls, 0);
  });

  test('1000 restores and replays are deterministic', () {
    final api = make(),
        workflow = api.create('project', 'Replay'),
        snapshot = api.saveState(workflow.id);
    for (var i = 0; i < 1000; i++) {
      api.restoreState(workflow.id, snapshot.id);
      api.replay(workflow.id, snapshot.id);
    }
    expect(api.engine.analytics.restores, 2000);
    expect(api.engine.analytics.replays, 1000);
    expect(workflow.currentIndex, 0);
    expect(
      workflow.steps.every((e) => e.state == WorkflowStepState.ready),
      isTrue,
    );
  });

  test('diagnostics validation and graph expose workflow state', () {
    final api = make(), workflow = api.create('', 'Invalid');
    expect(api.diagnostics(workflow.id), contains('Project ID is required'));
    expect(
      api.engine.graph.downstream(workflow.steps.first.id),
      contains(workflow.steps.last.id),
    );
  });

  test('repository Studio FEL and passive bootstrap integrate', () async {
    final api = make(), workflow = api.create('project', 'Persisted');
    api.saveState(workflow.id);
    await api.engine.persist();
    for (final path in WorkflowRepository.paths) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      ReverseWorkflowStudioAdapter.workspace,
      'Professional Reverse Engineering Workspace',
    );
    expect(ReverseWorkflowStudioAdapter.panels, hasLength(7));
    expect(
      ReverseWorkflowStudioAdapter()
          .buildTree(api.engine, 'project')
          .last
          .context['reverseWorkflow'],
      isTrue,
    );
    expect(
      createReverseWorkflowFelCommands(api).length,
      greaterThanOrEqualTo(80),
    );
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services.get<ReverseWorkflowRuntime>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<WorkflowHistory>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<WorkflowTimeline>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<WorkflowAnalytics>(),
      isNotNull,
    );
  });
}
