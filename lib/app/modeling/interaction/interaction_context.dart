enum ModelingSelectionType {
  face,
  surface,
  plane,
  axis,
  curve,
  point,
  meshRegion,
  feature,
}

enum InteractionStage {
  idle,
  selected,
  previewing,
  parameters,
  awaitingConfirmation,
  committed,
  cancelled,
}

class ModelingSelection {
  const ModelingSelection({
    required this.id,
    required this.name,
    required this.type,
    this.sourceIds = const [],
    this.evidence = const [],
  });
  final String id;
  final String name;
  final ModelingSelectionType type;
  final List<String> sourceIds;
  final List<String> evidence;
}

class InteractionContext {
  const InteractionContext({
    this.stage = InteractionStage.idle,
    this.selection = const [],
    this.toolId,
    this.parameters = const {},
    this.preview,
    this.message = 'Ready',
  });
  final InteractionStage stage;
  final List<ModelingSelection> selection;
  final String? toolId;
  final Map<String, Object?> parameters;
  final EngineeringPreview? preview;
  final String message;
  InteractionContext copyWith({
    InteractionStage? stage,
    List<ModelingSelection>? selection,
    String? toolId,
    Map<String, Object?>? parameters,
    EngineeringPreview? preview,
    String? message,
    bool clearTool = false,
    bool clearPreview = false,
  }) => InteractionContext(
    stage: stage ?? this.stage,
    selection: selection ?? this.selection,
    toolId: clearTool ? null : toolId ?? this.toolId,
    parameters: parameters ?? this.parameters,
    preview: clearPreview ? null : preview ?? this.preview,
    message: message ?? this.message,
  );
}

class EngineeringPreview {
  const EngineeringPreview({
    required this.id,
    required this.kind,
    required this.sourceIds,
    required this.parameters,
    required this.evidence,
    required this.confidence,
    required this.justification,
  });
  final String id;
  final String kind;
  final List<String> sourceIds;
  final Map<String, Object?> parameters;
  final List<String> evidence;
  final double confidence;
  final String justification;
}
