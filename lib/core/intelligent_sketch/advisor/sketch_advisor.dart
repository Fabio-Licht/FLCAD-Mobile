import '../entities/sketch_entity.dart';
import '../models/sketch.dart';

class SketchSuggestion {
  const SketchSuggestion(
    this.code,
    this.message,
    this.confidence, {
    this.metadata = const {},
  });
  final String code, message;
  final double confidence;
  final Map<String, dynamic> metadata;
}

abstract interface class SketchAdvisor {
  Future<List<SketchSuggestion>> advise(IntelligentSketch sketch);
}

class RuleBasedSketchAdvisor implements SketchAdvisor {
  const RuleBasedSketchAdvisor();
  @override
  Future<List<SketchSuggestion>> advise(IntelligentSketch sketch) async {
    final result = <SketchSuggestion>[];
    for (final entity in sketch.entities) {
      switch (entity.kind) {
        case SketchEntityKind.circle:
          result.add(
            const SketchSuggestion(
              'create-cylinder',
              'Create a cylinder from this circular profile?',
              .85,
            ),
          );
        case SketchEntityKind.spline:
          result.add(
            const SketchSuggestion(
              'guide-curve',
              'Use this spline as a guide curve?',
              .75,
            ),
          );
        case SketchEntityKind.rectangle:
          result.add(
            const SketchSuggestion(
              'create-profile',
              'Convert this rectangle to an engineering profile?',
              .8,
            ),
          );
        default:
          break;
      }
    }
    return result;
  }
}

abstract interface class SketchPredictor {
  Future<double> match(IntelligentSketch previous, IntelligentSketch candidate);
}

abstract interface class SketchGenerator {
  Future<IntelligentSketch> generate(String projectId, String intent);
}

abstract interface class SketchClassifier {
  Future<String> classify(IntelligentSketch sketch);
}

abstract interface class SketchOptimizer {
  Future<IntelligentSketch> optimize(IntelligentSketch sketch);
}
