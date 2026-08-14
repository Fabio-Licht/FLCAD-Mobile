import '../../utils/id_generator.dart';

enum SelectionType {
  meshRegion,
  recognizedPlane,
  recognizedCylinder,
  recognizedCone,
  recognizedSphere,
  datumPlane,
  datumAxis,
  datumPoint,
  sketch,
  feature,
  validationRegion,
  criticalRegion,
}

enum InteractiveOperation {
  createDatum,
  createSketch,
  openSketch,
  extrude,
  revolve,
  sweep,
  loft,
  alignment,
  validation,
  engineeringReview,
  showCause,
  validationReplay,
}

enum InteractionDecision { pending, accepted, ignored, cancelled }

class SelectionVector {
  const SelectionVector(this.x, this.y, this.z);
  final double x, y, z;
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

class SelectionBounds {
  const SelectionBounds(this.width, this.height, this.depth);
  final double width, height, depth;
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'depth': depth,
  };
}

class InteractiveSelection {
  InteractiveSelection({
    required this.objectId,
    required this.type,
    required this.workflowStep,
    this.quality = 0,
    this.confidence = 0,
    this.normal = const SelectionVector(0, 0, 1),
    this.bounds = const SelectionBounds(0, 0, 0),
    this.area = 0,
    this.radius = 0,
    this.curvature = 0,
    this.relatedFeature,
    this.localError = 0,
    this.references = const [],
    this.dependencies = const [],
    String? id,
  }) : id = id ?? 'selection:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, objectId, workflowStep;
  final SelectionType type;
  final double quality, confidence, area, radius, curvature, localError;
  final SelectionVector normal;
  final SelectionBounds bounds;
  final String? relatedFeature;
  final List<String> references, dependencies;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'objectId': objectId,
    'type': type.name,
    'workflowStep': workflowStep,
    'quality': quality,
    'confidence': confidence,
    'normal': normal.toJson(),
    'bounds': bounds.toJson(),
    'area': area,
    'radius': radius,
    'curvature': curvature,
    'relatedFeature': relatedFeature,
    'localError': localError,
    'references': references,
    'dependencies': dependencies,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ContextSuggestion {
  ContextSuggestion({
    required this.operation,
    required this.label,
    required this.command,
    required this.confidence,
    required this.explanation,
    required this.advantages,
    required this.alternatives,
    required this.expectedGain,
    String? id,
  }) : id = id ?? 'context-suggestion:${IdGenerator.generate()}';
  final String id, label, command, explanation;
  final InteractiveOperation operation;
  final double confidence, expectedGain;
  final List<String> advantages, alternatives;
  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation.name,
    'label': label,
    'command': command,
    'confidence': confidence,
    'explanation': explanation,
    'advantages': advantages,
    'alternatives': alternatives,
    'expectedGain': expectedGain,
  };
}

class InteractionIntent {
  InteractionIntent({
    required this.selectionId,
    required this.suggestion,
    String? id,
  }) : id = id ?? 'interaction-intent:${IdGenerator.generate()}',
       createdAt = DateTime.now().toUtc();
  final String id, selectionId;
  final ContextSuggestion suggestion;
  final DateTime createdAt;
  InteractionDecision decision = InteractionDecision.pending;
  Map<String, dynamic> toJson() => {
    'id': id,
    'selectionId': selectionId,
    'suggestion': suggestion.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'decision': decision.name,
  };
}

class SelectionPreview {
  const SelectionPreview({
    required this.selectionId,
    required this.highlight,
    required this.bounds,
    required this.normal,
    required this.area,
    required this.radius,
    required this.curvature,
    required this.relatedFeature,
    required this.localError,
    required this.confidence,
  });
  final String selectionId, highlight;
  final SelectionBounds bounds;
  final SelectionVector normal;
  final double area, radius, curvature, localError, confidence;
  final String? relatedFeature;
  Map<String, dynamic> toJson() => {
    'selectionId': selectionId,
    'highlight': highlight,
    'bounds': bounds.toJson(),
    'normal': normal.toJson(),
    'area': area,
    'radius': radius,
    'curvature': curvature,
    'relatedFeature': relatedFeature,
    'localError': localError,
    'confidence': confidence,
  };
}

class InteractiveDashboardState {
  String? selectedObject, recognizedType, relatedFeature, recommendation;
  double quality = 0, error = 0;
  final List<String> references = [], dependencies = [];
  Map<String, dynamic> toJson() => {
    'selectedObject': selectedObject,
    'recognizedType': recognizedType,
    'quality': quality,
    'error': error,
    'relatedFeature': relatedFeature,
    'references': references,
    'dependencies': dependencies,
    'recommendation': recommendation,
  };
}
