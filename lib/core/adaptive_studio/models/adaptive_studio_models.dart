import '../../utils/id_generator.dart';

enum AdaptiveContext {
  importMesh,
  recognition,
  reference,
  alignment,
  validation,
  sketch,
  constraints,
  profiles,
  featureModeling,
  review,
  finalization,
}

enum FocusMode {
  maximumViewport,
  minimalUi,
  sketchFocus,
  validationFocus,
  modelingFocus,
  presentation,
}

enum DockState { docked, undocked, autoHidden, pinned, floating, snapped }

enum StudioNotificationType {
  success,
  warning,
  critical,
  recommendation,
  validation,
  recognition,
  alignment,
  feature,
}

class AdaptivePanel {
  AdaptivePanel(
    this.id,
    this.title, {
    this.visible = true,
    this.dockState = DockState.docked,
    this.monitor = 0,
  });
  final String id;
  String title;
  bool visible;
  DockState dockState;
  int monitor;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'visible': visible,
    'dockState': dockState.name,
    'monitor': monitor,
  };
}

class RibbonGroup {
  const RibbonGroup(this.name, this.actions);
  final String name;
  final List<String> actions;
  Map<String, dynamic> toJson() => {'name': name, 'actions': actions};
}

class QuickAction {
  const QuickAction({
    required this.id,
    required this.label,
    required this.command,
    required this.recommendationId,
    required this.explanation,
  });
  final String id, label, command, recommendationId, explanation;
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'command': command,
    'recommendationId': recommendationId,
    'explanation': explanation,
  };
}

class NavigationState {
  final List<String> breadcrumb = [],
      recentObjects = [],
      recentFeatures = [],
      recentReferences = [];
  final Set<String> favorites = {}, pinnedObjects = {};
  Map<String, dynamic> toJson() => {
    'breadcrumb': breadcrumb,
    'recentObjects': recentObjects,
    'recentFeatures': recentFeatures,
    'recentReferences': recentReferences,
    'favorites': favorites.toList(),
    'pinnedObjects': pinnedObjects.toList(),
  };
}

class DashboardState {
  DashboardState({
    this.workflow = '',
    this.projectHealth = 0,
    this.engineeringScore = 0,
    this.recognitionStatus = 'idle',
    this.alignmentStatus = 'idle',
    this.validationStatus = 'idle',
    this.heatMapStatus = 'idle',
    this.currentFeature,
    this.progress = 0,
  });
  String workflow,
      recognitionStatus,
      alignmentStatus,
      validationStatus,
      heatMapStatus;
  String? currentFeature;
  double projectHealth, engineeringScore, progress;
  final List<String> recommendations = [], timeline = [], checklist = [];
  Map<String, dynamic> toJson() => {
    'workflow': workflow,
    'projectHealth': projectHealth,
    'engineeringScore': engineeringScore,
    'recognitionStatus': recognitionStatus,
    'alignmentStatus': alignmentStatus,
    'validationStatus': validationStatus,
    'heatMapStatus': heatMapStatus,
    'currentFeature': currentFeature,
    'progress': progress,
    'recommendations': recommendations,
    'timeline': timeline,
    'checklist': checklist,
  };
}

class AdaptiveWorkspaceState {
  AdaptiveWorkspaceState({required this.projectId})
    : id = 'adaptive-workspace:${IdGenerator.generate()}';
  final String id, projectId;
  AdaptiveContext context = AdaptiveContext.importMesh;
  FocusMode? focusMode;
  bool showAll = false;
  final Map<String, AdaptivePanel> panels = {};
  final List<RibbonGroup> ribbon = [];
  final List<String> toolbars = [], filters = [], columns = [];
  final List<QuickAction> quickActions = [];
  final NavigationState navigation = NavigationState();
  final DashboardState dashboard = DashboardState();
  String? currentFeature,
      workflowStep,
      activeQuickAction,
      engineeringRecommendation;
  int layoutVersion = 1;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'context': context.name,
    'focusMode': focusMode?.name,
    'showAll': showAll,
    'panels': panels.values.map((e) => e.toJson()).toList(),
    'ribbon': ribbon.map((e) => e.toJson()).toList(),
    'toolbars': toolbars,
    'filters': filters,
    'columns': columns,
    'quickActions': quickActions.map((e) => e.toJson()).toList(),
    'navigation': navigation.toJson(),
    'dashboard': dashboard.toJson(),
    'currentFeature': currentFeature,
    'workflowStep': workflowStep,
    'activeQuickAction': activeQuickAction,
    'engineeringRecommendation': engineeringRecommendation,
    'layoutVersion': layoutVersion,
  };
}

class StudioNotification {
  StudioNotification({required this.type, required this.message, String? id})
    : id = id ?? 'studio-notification:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, message;
  final StudioNotificationType type;
  final DateTime timestamp;
  bool read = false;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'read': read,
    'modal': false,
  };
}

class WorkspaceMemory {
  WorkspaceMemory({
    required this.workspaceId,
    required this.context,
    required this.focusMode,
    required this.showAll,
    required this.panelStates,
    required this.ribbonNames,
    required this.toolbars,
    required this.filters,
    required this.columns,
    String? id,
  }) : id = id ?? 'workspace-memory:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, workspaceId;
  final AdaptiveContext context;
  final FocusMode? focusMode;
  final bool showAll;
  final Map<String, DockState> panelStates;
  final List<String> ribbonNames, toolbars, filters, columns;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'context': context.name,
    'focusMode': focusMode?.name,
    'showAll': showAll,
    'panelStates': panelStates.map((k, v) => MapEntry(k, v.name)),
    'ribbonNames': ribbonNames,
    'toolbars': toolbars,
    'filters': filters,
    'columns': columns,
    'timestamp': timestamp.toIso8601String(),
  };
}
