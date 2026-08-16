import 'dart:io';

class CommandContext {
  CommandContext({
    required this.projectId,
    required this.projectDirectory,
    this.selection = const <String>{},
    this.attributes = const <String, Object?>{},
  });

  final String? projectId;
  final Directory? projectDirectory;
  final Set<String> selection;
  final Map<String, Object?> attributes;

  bool get hasProject => projectId != null && projectDirectory != null;

  CommandContext copyWith({
    String? projectId,
    Directory? projectDirectory,
    Set<String>? selection,
    Map<String, Object?>? attributes,
    bool clearProject = false,
  }) => CommandContext(
    projectId: clearProject ? null : projectId ?? this.projectId,
    projectDirectory: clearProject
        ? null
        : projectDirectory ?? this.projectDirectory,
    selection: selection ?? this.selection,
    attributes: attributes ?? this.attributes,
  );
}
