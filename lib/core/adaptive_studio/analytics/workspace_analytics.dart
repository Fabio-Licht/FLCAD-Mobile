class WorkspaceAnalytics {
  int workspaceChanges = 0,
      layoutChanges = 0,
      quickActions = 0,
      focusChanges = 0,
      restores = 0,
      dockingChanges = 0,
      ribbonChanges = 0,
      dashboardUpdates = 0,
      panelUses = 0;
  final Map<String, int> workspaceMicros = {};
  Map<String, dynamic> toJson() => {
    'workspaceChanges': workspaceChanges,
    'layoutChanges': layoutChanges,
    'quickActions': quickActions,
    'focusChanges': focusChanges,
    'restores': restores,
    'dockingChanges': dockingChanges,
    'ribbonChanges': ribbonChanges,
    'dashboardUpdates': dashboardUpdates,
    'panelUses': panelUses,
    'workspaceMicros': workspaceMicros,
  };
}
