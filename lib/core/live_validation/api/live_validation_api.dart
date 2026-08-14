import '../advisor/validation_advisor.dart';
import '../builders/validation_builder.dart';
import '../engine/live_validation_engine.dart';
import '../history/validation_history.dart';
import '../models/validation_models.dart';
import '../preview/heat_map.dart';
import '../validation/live_validation_validation.dart';
import '../validation/validation_quality.dart';

class LiveValidationApi {
  LiveValidationApi(this.engine) : builder = ValidationBuilder(engine);
  final LiveValidationEngine engine;
  final ValidationBuilder builder;
  List<LiveValidationSession> get sessions =>
      List.unmodifiable(engine.sessions.values);
  Future<ValidationExecutionResult> start(String id) => engine.start(id);
  void pause(String id) => engine.pause(id);
  void resume(String id) => engine.resume(id);
  void stop(String id) => engine.stop(id);
  HeatMapPreview heatMap(String id) => engine.heatMap(id);
  LiveValidationValidationResult validate(String id) => engine.validate(id);
  ValidationQuality quality(String id) => engine.quality(id);
  List<ValidationRecommendation> recommendations(String id) =>
      engine.recommendations(id);
  ValidationSnapshot snapshot(String id) => engine.snapshot(id);
}
