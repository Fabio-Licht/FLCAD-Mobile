import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/adaptive_studio/analytics/workspace_analytics.dart';
import 'package:flcad_mobile/core/adaptive_studio/api/adaptive_studio_api.dart';
import 'package:flcad_mobile/core/adaptive_studio/commands/fel_adaptive_studio_commands.dart';
import 'package:flcad_mobile/core/adaptive_studio/history/workspace_history.dart';
import 'package:flcad_mobile/core/adaptive_studio/integration/adaptive_studio_adapter.dart';
import 'package:flcad_mobile/core/adaptive_studio/integration/adaptive_studio_factory.dart';
import 'package:flcad_mobile/core/adaptive_studio/models/adaptive_studio_models.dart';
import 'package:flcad_mobile/core/adaptive_studio/repository/adaptive_studio_repository.dart';
import 'package:flcad_mobile/core/adaptive_studio/runtime/adaptive_studio_runtime.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/engineering_intelligence/models/intelligence_models.dart';
import 'package:flcad_mobile/core/reverse_workflow/models/workflow_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedStudioKernel implements GeometryKernelAPI {
  int calls = 0;
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'unused',
    name: 'Unused Studio kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities.none,
  );
  Never _called() {
    calls++;
    throw StateError('Adaptive Studio must not invoke the kernel');
  }

  @override
  Future<KernelHealth> healthCheck() async => _called();
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async => _called();
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      _called();
  @override
  Future<void> begin(KernelTransaction transaction) async => _called();
  @override
  Future<void> commit(KernelTransaction transaction) async => _called();
  @override
  Future<void> rollback(KernelTransaction transaction) async => _called();
  @override
  Future<void> unload() async => _called();
}

void main() {
  late Directory project;
  late _UnusedStudioKernel kernel;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_adaptive_');
    kernel = _UnusedStudioKernel();
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  AdaptiveStudioApi make() => const AdaptiveStudioFactory().create(
    projectDirectory: project,
    kernel: kernel,
  );
  ReverseWorkflow workflow({int index = 0}) =>
      ReverseWorkflow(projectId: 'project', name: 'Reverse')
        ..currentIndex = index;
  EngineeringRecommendation recommendation(int index) =>
      EngineeringRecommendation(
        type: RecommendationType.nextOperation,
        title: 'Recommendation $index',
        confidence: .9,
        explanation: 'Consultative action',
        technicalReason: 'Current workflow evidence',
        advantages: const ['Focused'],
        disadvantages: const ['Requires confirmation'],
        alternatives: const ['Review'],
        expectedImprovement: 5,
        affectedFeatures: const ['feature'],
        affectedReferences: const ['reference'],
      );

  test('all adaptive contexts focus modes docking and notifications exist', () {
    expect(AdaptiveContext.values, hasLength(11));
    expect(FocusMode.values, hasLength(6));
    expect(DockState.values, hasLength(6));
    expect(StudioNotificationType.values, hasLength(8));
    final api = make(), state = api.create('project');
    expect(state.context, AdaptiveContext.importMesh);
    expect(
      state.panels.values.where((e) => e.visible).map((e) => e.title),
      containsAll(['Project', 'Import', 'Mesh Inspector']),
    );
    expect(kernel.calls, 0);
  });

  test(
    'workflow context adapts panels ribbon toolbar without executing work',
    () {
      final api = make(),
          state = api.create('project'),
          flow = workflow(index: ReverseWorkflowStepType.alignment.index);
      api.adaptTo(state.id, flow, recommendations: [recommendation(1)]);
      expect(state.context, AdaptiveContext.alignment);
      expect(
        state.ribbon.single.actions,
        containsAll(['Plane Alignment', 'Axis Alignment', 'Best Fit', 'ICP']),
      );
      expect(
        state.panels.values.where((e) => e.visible).map((e) => e.title),
        contains('Alignment Preview'),
      );
      expect(state.quickActions, hasLength(1));
      expect(state.activeQuickAction, isNotNull);
      expect(flow.currentIndex, ReverseWorkflowStepType.alignment.index);
      expect(kernel.calls, 0);
    },
  );

  test('progressive disclosure and show-all preserve panel preferences', () {
    final api = make(), state = api.create('project');
    api.engine.changeContext(state.id, AdaptiveContext.recognition);
    expect(
      state.panels.values
          .where((e) => e.visible)
          .every(
            (e) => ['Recognition', 'Regions', 'Statistics'].contains(e.title),
          ),
      isTrue,
    );
    api.engine.showAll(state.id, true);
    expect(state.panels.values.every((e) => e.visible), isTrue);
    api.engine.showAll(state.id, false);
    expect(
      state.panels.values.where((e) => e.visible).map((e) => e.title),
      containsAll(['Recognition', 'Regions', 'Statistics']),
    );
  });

  test(
    'docking navigation notifications dashboard and quick actions integrate',
    () {
      final api = make(),
          state = api.create('project'),
          flow = workflow(),
          rec = recommendation(1);
      api.adaptTo(state.id, flow, recommendations: [rec]);
      api.engine.dock(state.id, 'project', DockState.floating, monitor: 2);
      expect(state.panels['project']?.monitor, 2);
      api.engine.visit(state.id, 'feature-1', kind: 'feature');
      api.engine.navigation.favorite(state.navigation, 'feature-1', true);
      api.engine.navigation.pin(state.navigation, 'feature-1', true);
      api.engine.notify(
        state.id,
        StudioNotificationType.recommendation,
        'Review suggestion',
      );
      api.engine.useQuickAction(state.id, state.quickActions.single.id);
      api.engine.updateDashboard(
        state.id,
        flow,
        recognition: 'ready',
        alignment: 'pending',
        validation: 'idle',
        currentFeature: 'feature-1',
        checklist: const ['STL imported'],
      );
      expect(state.navigation.recentFeatures, contains('feature-1'));
      expect(state.navigation.favorites, contains('feature-1'));
      expect(
        api.engine.notifications.notifications.single.toJson()['modal'],
        isFalse,
      );
      expect(state.dashboard.currentFeature, 'feature-1');
      expect(state.activeQuickAction, isNotNull);
      expect(flow.currentIndex, 0);
      expect(kernel.calls, 0);
    },
  );

  test(
    '1000 workspace layout quick focus ribbon dashboard and restore changes',
    () {
      final api = make(),
          state = api.create('project'),
          flow = workflow(),
          rec = recommendation(1);
      api.adaptTo(state.id, flow, recommendations: [rec]);
      final initial = api.saveLayout(state.id);
      for (var i = 0; i < 1000; i++) {
        api.engine.changeContext(
          state.id,
          AdaptiveContext.values[i % AdaptiveContext.values.length],
        );
        api.saveLayout(state.id);
        api.engine.setFocus(
          state.id,
          FocusMode.values[i % FocusMode.values.length],
        );
        api.engine.useQuickAction(state.id, state.quickActions.single.id);
        api.restoreLayout(state.id, initial.id);
        api.adaptTo(state.id, flow, recommendations: [rec]);
        api.engine.updateDashboard(
          state.id,
          flow,
          currentFeature: 'feature-$i',
        );
      }
      expect(api.engine.analytics.workspaceChanges, 2001);
      expect(api.engine.analytics.layoutChanges, 1001);
      expect(api.engine.analytics.quickActions, 1000);
      expect(api.engine.analytics.focusChanges, 1000);
      expect(api.engine.analytics.restores, 1000);
      expect(api.engine.analytics.ribbonChanges, 1001);
      expect(api.engine.analytics.dashboardUpdates, 1000);
      expect(api.engine.memories, hasLength(1001));
      expect(kernel.calls, 0);
    },
  );

  test('1000 dock and undock operations are deterministic', () {
    final api = make(), state = api.create('project');
    for (var i = 0; i < 1000; i++) {
      api.engine.dock(state.id, 'project', DockState.undocked);
      api.engine.dock(state.id, 'project', DockState.docked);
    }
    expect(api.engine.analytics.dockingChanges, 2000);
    expect(state.panels['project']?.dockState, DockState.docked);
  });

  test('workspace memory restores layout focus filters and columns', () {
    final api = make(), state = api.create('project');
    state
      ..filters.add('critical')
      ..columns.add('RMS');
    api.engine.setFocus(state.id, FocusMode.validationFocus);
    api.engine.dock(state.id, 'project', DockState.pinned);
    final memory = api.saveLayout(state.id);
    api.engine.resetLayout(state.id);
    state
      ..filters.clear()
      ..columns.clear();
    api.restoreLayout(state.id, memory.id);
    expect(state.focusMode, FocusMode.validationFocus);
    expect(state.filters, ['critical']);
    expect(state.columns, ['RMS']);
    expect(state.panels['project']?.dockState, DockState.pinned);
  });

  test('repository Studio FEL and passive bootstrap integrate', () async {
    final api = make(), state = api.create('project');
    api.saveLayout(state.id);
    await api.engine.persist();
    for (final path in AdaptiveStudioRepository.paths) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      AdaptiveStudioAdapter.workspace,
      'Adaptive Reverse Engineering Studio',
    );
    expect(
      AdaptiveStudioAdapter()
          .buildTree(api.engine, 'project')
          .single
          .context['adaptiveStudio'],
      isTrue,
    );
    expect(
      createAdaptiveStudioFelCommands(api).length,
      greaterThanOrEqualTo(100),
    );
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services.get<AdaptiveStudioRuntime>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<WorkspaceHistory>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<WorkspaceAnalytics>(),
      isNotNull,
    );
  });
}
