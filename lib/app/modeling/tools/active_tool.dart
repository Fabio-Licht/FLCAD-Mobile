import '../interaction/interaction_context.dart';

typedef PreviewBuilder =
    Future<EngineeringPreview> Function(
      List<ModelingSelection> selection,
      Map<String, Object?> parameters,
    );
typedef CommitAction = Future<Object?> Function(EngineeringPreview preview);

class ActiveTool {
  const ActiveTool({
    required this.id,
    required this.label,
    required this.allowedSelection,
    required this.defaultParameters,
    required this.previewBuilder,
    required this.commit,
  });
  final String id;
  final String label;
  final Set<ModelingSelectionType> allowedSelection;
  final Map<String, Object?> defaultParameters;
  final PreviewBuilder previewBuilder;
  final CommitAction commit;
}
