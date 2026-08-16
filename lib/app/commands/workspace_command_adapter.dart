class WorkspaceCommandState {
  const WorkspaceCommandState({
    this.workspace = 'AI Engineering',
    this.selection = const <String>{},
    this.status = 'Ready',
  });
  final String workspace;
  final Set<String> selection;
  final String status;
  WorkspaceCommandState copyWith({
    String? workspace,
    Set<String>? selection,
    String? status,
  }) => WorkspaceCommandState(
    workspace: workspace ?? this.workspace,
    selection: selection ?? this.selection,
    status: status ?? this.status,
  );
}

class WorkspaceCommandAdapter {
  WorkspaceCommandState state = const WorkspaceCommandState();
  void open(String workspace) => state = state.copyWith(
    workspace: workspace,
    status: '$workspace workspace active',
  );
  void select(Set<String> selection) => state = state.copyWith(
    selection: Set.unmodifiable(selection),
    status: '${selection.length} object(s) selected',
  );
}
