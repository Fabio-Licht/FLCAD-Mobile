import '../advisor/extrude_advisor.dart';
import '../builders/extrude_builder.dart';
import '../engine/extrude_engine.dart';
import '../models/extrude_models.dart';
import '../preview/extrude_preview.dart';
import '../validation/extrude_quality.dart';
import '../validation/extrude_validation.dart';

class ExtrudeApi {
  ExtrudeApi(this.engine) : builder = ExtrudeBuilder(engine);
  final ExtrudeEngine engine;
  final ExtrudeBuilder builder;
  List<ExtrudeFeature> get extrudes =>
      List.unmodifiable(engine.extrudes.values);
  ExtrudePreview preview(String id) => engine.preview(id);
  Future<ExtrudeExecutionResult> confirm(String id) => engine.confirm(id);
  Future<ExtrudeExecutionResult> rebuild(String id) => engine.rebuild(id);
  void rollback(String id) => engine.rollback(id);
  ExtrudeValidationResult validate(String id) => engine.validate(id);
  ExtrudeQuality quality(String id) => engine.quality(id);
  List<ExtrudeRecommendation> recommendations(String id) =>
      engine.recommendations(id);
}
