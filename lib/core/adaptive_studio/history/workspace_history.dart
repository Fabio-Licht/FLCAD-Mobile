import '../../utils/id_generator.dart';

enum WorkspaceHistoryAction {
  create,
  context,
  layout,
  restore,
  reset,
  focus,
  dock,
  ribbon,
  dashboard,
  quickAction,
  navigation,
  notification,
}

class WorkspaceHistoryEntry {
  WorkspaceHistoryEntry(this.action, this.workspaceId, this.detail)
    : id = 'workspace-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, workspaceId, detail;
  final WorkspaceHistoryAction action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'action': action.name,
    'detail': detail,
    'timestamp': timestamp.toIso8601String(),
  };
}

class WorkspaceHistory {
  final List<WorkspaceHistoryEntry> entries = [];
  void record(
    WorkspaceHistoryAction action,
    String workspaceId,
    String detail,
  ) => entries.add(WorkspaceHistoryEntry(action, workspaceId, detail));
}
