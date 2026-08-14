import '../advisor/reference_advisor.dart';
import '../builders/reference_builder.dart';
import '../engine/reference_engine.dart';
import '../models/reference_models.dart';
import '../preview/reference_preview.dart';
import '../validation/reference_quality.dart';
import '../validation/reference_validation.dart';

class ReferenceApi {
  ReferenceApi(this.engine) : builder = ReferenceBuilder(engine);
  final ReferenceEngine engine;
  final ReferenceBuilder builder;
  List<ReferenceEntity> get references =>
      List.unmodifiable(engine.references.values);
  ReferencePreview preview(String id) => engine.preview(id);
  Future<ReferenceExecutionResult> confirm(String id) => engine.confirm(id);
  Future<ReferenceExecutionResult> rebuild(String id) => engine.rebuild(id);
  ReferenceValidationResult validate(String id) => engine.validate(id);
  ReferenceQuality quality(String id) => engine.quality(id);
  List<ReferenceRecommendation> recommendations(String id) =>
      engine.recommendations(id);
}
