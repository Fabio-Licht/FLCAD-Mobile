import '../advisor/revolve_advisor.dart';
import '../builders/revolve_builder.dart';
import '../engine/revolve_engine.dart';
import '../models/revolve_models.dart';
import '../preview/revolve_preview.dart';
import '../validation/revolve_quality.dart';
import '../validation/revolve_validation.dart';

class RevolveApi {
  RevolveApi(this.engine) : builder = RevolveBuilder(engine);
  final RevolveEngine engine;
  final RevolveBuilder builder;
  List<RevolveFeature> get revolves =>
      List.unmodifiable(engine.revolves.values);
  RevolvePreview preview(String id) => engine.preview(id);
  Future<RevolveExecutionResult> confirm(String id) => engine.confirm(id);
  Future<RevolveExecutionResult> rebuild(String id) => engine.rebuild(id);
  void rollback(String id) => engine.rollback(id);
  RevolveValidationResult validate(String id) => engine.validate(id);
  RevolveQuality quality(String id) => engine.quality(id);
  List<RevolveRecommendation> recommendations(String id) =>
      engine.recommendations(id);
}
