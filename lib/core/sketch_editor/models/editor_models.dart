import '../../sketch_engine/models/sketch_models.dart';
import '../../utils/id_generator.dart';

enum SketchToolType {
  point,
  line,
  polyline,
  rectangle,
  centerRectangle,
  circle,
  centerCircle,
  threePointCircle,
  arc,
  threePointArc,
  tangentArc,
  ellipse,
  spline,
  slot,
  polygon,
  construction,
  reference,
  move,
  rotate,
  scale,
  stretch,
  mirror,
  offset,
  trim,
  extend,
  breakEntity,
  split,
  join,
  fillet,
  chamfer,
  duplicate,
  copy,
  delete,
  convertConstruction,
  convertReference,
  lock,
  unlock,
}

enum SketchVisualState {
  normal,
  construction,
  reference,
  driven,
  driving,
  selected,
  hover,
  preselected,
  conflicting,
  suppressed,
  disabled,
  locked,
  overdefined,
  underdefined,
}

enum EditorOperationStatus { preview, committed, cancelled, failed }

class EditorOperation {
  EditorOperation(
    this.tool, {
    required this.points,
    Map<String, dynamic>? parameters,
    String? id,
  }) : id = id ?? 'editor-op:${IdGenerator.generate()}',
       parameters = parameters ?? <String, dynamic>{};
  final String id;
  final SketchToolType tool;
  final List<SketchVector> points;
  final Map<String, dynamic> parameters;
  EditorOperationStatus status = EditorOperationStatus.preview;
}

class DegreesOfFreedom {
  const DegreesOfFreedom({
    required this.remaining,
    required this.translationX,
    required this.translationY,
    required this.rotation,
    required this.constraintStatus,
    this.diagnostics = const [],
  });
  final int remaining;
  final bool translationX, translationY, rotation;
  final String constraintStatus;
  final List<String> diagnostics;
}

enum SketchQualityGrade { excellent, good, fair, poor }

class SketchQuality {
  const SketchQuality(this.score, this.grade, this.factors);
  final int score;
  final SketchQualityGrade grade;
  final Map<String, num> factors;
}

enum AdvisorKind {
  sketch,
  constraint,
  dof,
  selection,
  construction,
  reference,
  quality,
  conflict,
}

class SketchRecommendation {
  SketchRecommendation({
    required this.kind,
    required this.title,
    required this.description,
    required this.reason,
    required this.confidence,
    required this.expectedImpact,
    required this.suggestedAction,
    required this.technicalExplanation,
    String? id,
  }) : id = id ?? 'recommendation:${IdGenerator.generate()}' {
    if (confidence < 0 || confidence > 100) {
      throw RangeError.range(confidence, 0, 100, 'confidence');
    }
  }
  final String id;
  final AdvisorKind kind;
  final String title,
      description,
      reason,
      expectedImpact,
      suggestedAction,
      technicalExplanation;
  final int confidence;
}
