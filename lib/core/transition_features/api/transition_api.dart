import '../advisor/transition_advisor.dart';
import '../builders/transition_builders.dart';
import '../engine/transition_engine.dart';
import '../models/transition_models.dart';
import '../preview/transition_preview.dart';
import '../validation/transition_quality.dart';
import '../validation/transition_validation.dart';

class TransitionApi {
  TransitionApi(this.engine)
    : sweeps = SweepBuilder(engine),
      lofts = LoftBuilder(engine);
  final TransitionEngine engine;
  final SweepBuilder sweeps;
  final LoftBuilder lofts;
  List<TransitionFeature> get features =>
      List.unmodifiable(engine.features.values);
  TransitionPreview preview(String id) => engine.preview(id);
  Future<TransitionExecutionResult> confirm(String id) => engine.confirm(id);
  Future<TransitionExecutionResult> rebuild(String id) => engine.rebuild(id);
  void rollback(String id) => engine.rollback(id);
  TransitionValidationResult validate(String id) => engine.validate(id);
  TransitionQuality quality(String id) => engine.quality(id);
  List<TransitionRecommendation> recommendations(String id) =>
      engine.recommendations(id);
}
