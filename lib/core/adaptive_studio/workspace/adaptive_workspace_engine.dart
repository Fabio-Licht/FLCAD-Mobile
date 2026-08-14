import '../../engineering_intelligence/models/intelligence_models.dart';
import '../../reverse_workflow/models/workflow_models.dart';
import '../advisor/quick_action_advisor.dart';
import '../analytics/workspace_analytics.dart';
import '../dashboard/adaptive_dashboard.dart';
import '../dock/docking_system.dart';
import '../history/workspace_history.dart';
import '../layouts/context_layouts.dart';
import '../models/adaptive_studio_models.dart';
import '../navigation/studio_navigation.dart';
import '../notifications/notification_center.dart';
import '../repository/adaptive_studio_repository.dart';
import '../runtime/adaptive_studio_runtime.dart';

class AdaptiveWorkspaceEngine {
  AdaptiveWorkspaceEngine({
    required this.repository,
    AdaptiveStudioRuntime? runtime,
    WorkspaceAnalytics? analytics,
    WorkspaceHistory? history,
  }) : runtime = runtime ?? AdaptiveStudioRuntime(),
       analytics = analytics ?? WorkspaceAnalytics(),
       history = history ?? WorkspaceHistory();
  final AdaptiveStudioRepository repository;
  final AdaptiveStudioRuntime runtime;
  final WorkspaceAnalytics analytics;
  final WorkspaceHistory history;
  final docking = DockingSystem();
  final navigation = const StudioNavigation();
  final notifications = NotificationCenter();
  final Map<String, AdaptiveWorkspaceState> workspaces = {};
  final Map<String, WorkspaceMemory> memories = {};
  AdaptiveWorkspaceState create(String projectId) {
    final state = AdaptiveWorkspaceState(projectId: projectId);
    workspaces[state.id] = state;
    _applyContext(state, AdaptiveContext.importMesh);
    history.record(WorkspaceHistoryAction.create, state.id, projectId);
    return state;
  }

  void adaptTo(
    String id,
    ReverseWorkflow workflow, {
    Iterable<EngineeringRecommendation> recommendations = const [],
  }) {
    final state = _get(id), context = _context(workflow.currentStep.type);
    state
      ..context = context
      ..workflowStep = workflow.currentStep.type.name
      ..engineeringRecommendation = recommendations.firstOrNull?.title;
    _applyContext(state, context);
    state.quickActions
      ..clear()
      ..addAll(const QuickActionAdvisor().suggest(workflow, recommendations));
    state.activeQuickAction = state.quickActions.firstOrNull?.id;
    analytics.workspaceChanges++;
    analytics.ribbonChanges++;
    history.record(WorkspaceHistoryAction.context, id, context.name);
  }

  void _applyContext(AdaptiveWorkspaceState state, AdaptiveContext context) {
    final layout = const ContextLayoutCatalog().forContext(context),
        relevant = layout.panels.toSet();
    for (final title in layout.panels) {
      final key = title.toLowerCase().replaceAll(' ', '-');
      state.panels.putIfAbsent(key, () => AdaptivePanel(key, title)).visible =
          true;
    }
    if (!state.showAll) {
      for (final panel in state.panels.values) {
        panel.visible = relevant.contains(panel.title);
      }
    }
    state.ribbon
      ..clear()
      ..addAll(layout.ribbon);
    state.toolbars
      ..clear()
      ..addAll(layout.toolbars);
    state.layoutVersion++;
  }

  void changeContext(String id, AdaptiveContext context) {
    final state = _get(id);
    state.context = context;
    _applyContext(state, context);
    analytics.workspaceChanges++;
    history.record(WorkspaceHistoryAction.context, id, context.name);
  }

  void showAll(String id, bool value) {
    final state = _get(id);
    state.showAll = value;
    if (value) {
      for (final panel in state.panels.values) {
        panel.visible = true;
      }
    } else {
      _applyContext(state, state.context);
    }
  }

  void setFocus(String id, FocusMode? mode) {
    final state = _get(id);
    state.focusMode = mode;
    analytics.focusChanges++;
    history.record(WorkspaceHistoryAction.focus, id, mode?.name ?? 'off');
  }

  void useQuickAction(String id, String actionId) {
    final state = _get(id);
    if (!state.quickActions.any((e) => e.id == actionId)) {
      throw StateError('Unknown quick action: $actionId');
    }
    state.activeQuickAction = actionId;
    analytics.quickActions++;
    history.record(WorkspaceHistoryAction.quickAction, id, actionId);
  }

  void dock(String id, String panelId, DockState state, {int monitor = 0}) {
    final panel =
        _get(id).panels[panelId] ??
        (throw StateError('Unknown panel: $panelId'));
    switch (state) {
      case DockState.docked:
        docking.dock(panel);
      case DockState.undocked:
        docking.undock(panel);
      case DockState.autoHidden:
        docking.autoHide(panel);
      case DockState.pinned:
        docking.pin(panel);
      case DockState.floating:
        docking.float(panel, monitor: monitor);
      case DockState.snapped:
        docking.snap(panel);
    }
    analytics.dockingChanges++;
    history.record(WorkspaceHistoryAction.dock, id, '$panelId:${state.name}');
  }

  WorkspaceMemory saveLayout(String id) {
    final state = _get(id),
        memory = WorkspaceMemory(
          workspaceId: id,
          context: state.context,
          focusMode: state.focusMode,
          showAll: state.showAll,
          panelStates: state.panels.map(
            (key, value) => MapEntry(key, value.dockState),
          ),
          ribbonNames: state.ribbon.map((e) => e.name).toList(),
          toolbars: List.of(state.toolbars),
          filters: List.of(state.filters),
          columns: List.of(state.columns),
        );
    memories[memory.id] = memory;
    analytics.layoutChanges++;
    history.record(WorkspaceHistoryAction.layout, id, memory.id);
    return memory;
  }

  void restoreLayout(String id, String memoryId) {
    final state = _get(id),
        memory =
            memories[memoryId] ??
            (throw StateError('Unknown workspace memory: $memoryId'));
    state
      ..context = memory.context
      ..focusMode = memory.focusMode
      ..showAll = memory.showAll
      ..toolbars.clear()
      ..toolbars.addAll(memory.toolbars)
      ..filters.clear()
      ..filters.addAll(memory.filters)
      ..columns.clear()
      ..columns.addAll(memory.columns);
    _applyContext(state, memory.context);
    for (final entry in memory.panelStates.entries) {
      final panel = state.panels[entry.key];
      if (panel != null) panel.dockState = entry.value;
    }
    analytics.restores++;
    history.record(WorkspaceHistoryAction.restore, id, memoryId);
  }

  void resetLayout(String id) {
    final state = _get(id);
    state
      ..focusMode = null
      ..showAll = false
      ..panels.clear();
    _applyContext(state, state.context);
    analytics.layoutChanges++;
    history.record(WorkspaceHistoryAction.reset, id, state.context.name);
  }

  void updateDashboard(
    String id,
    ReverseWorkflow workflow, {
    String recognition = 'idle',
    String alignment = 'idle',
    String validation = 'idle',
    String heatMap = 'idle',
    String? currentFeature,
    Iterable<String> timeline = const [],
    Iterable<String> checklist = const [],
  }) {
    final state = _get(id);
    const AdaptiveDashboard().update(
      state.dashboard,
      workflow,
      recognition: recognition,
      alignment: alignment,
      validation: validation,
      heatMap: heatMap,
      currentFeature: currentFeature,
      timeline: timeline,
      checklist: checklist,
    );
    state.currentFeature = currentFeature;
    analytics.dashboardUpdates++;
    history.record(WorkspaceHistoryAction.dashboard, id, workflow.id);
  }

  void visit(String id, String objectId, {String kind = 'object'}) {
    navigation.visit(_get(id).navigation, objectId, kind: kind);
    history.record(WorkspaceHistoryAction.navigation, id, objectId);
  }

  void notify(String id, StudioNotificationType type, String message) {
    notifications.notify(type, message);
    history.record(WorkspaceHistoryAction.notification, id, type.name);
  }

  AdaptiveContext _context(ReverseWorkflowStepType step) => switch (step) {
    ReverseWorkflowStepType.importMesh => AdaptiveContext.importMesh,
    ReverseWorkflowStepType.recognition => AdaptiveContext.recognition,
    ReverseWorkflowStepType.referenceGeometry => AdaptiveContext.reference,
    ReverseWorkflowStepType.alignment => AdaptiveContext.alignment,
    ReverseWorkflowStepType.validation ||
    ReverseWorkflowStepType.validationUpdate => AdaptiveContext.validation,
    ReverseWorkflowStepType.sketch => AdaptiveContext.sketch,
    ReverseWorkflowStepType.constraintSolve => AdaptiveContext.constraints,
    ReverseWorkflowStepType.profileRecognition => AdaptiveContext.profiles,
    ReverseWorkflowStepType.featureCreation => AdaptiveContext.featureModeling,
    ReverseWorkflowStepType.engineeringReview => AdaptiveContext.review,
    ReverseWorkflowStepType.projectComplete => AdaptiveContext.finalization,
  };
  AdaptiveWorkspaceState _get(String id) =>
      workspaces[id] ?? (throw StateError('Unknown adaptive workspace: $id'));
  Future<void> persist() => repository.save(
    workspaces: workspaces.values,
    memories: memories.values,
    history: history,
    analytics: analytics,
    notifications: notifications.notifications,
  );
}
