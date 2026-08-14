import '../advisor/feature_advisor.dart';
import '../builders/feature_builders.dart';
import '../engine/feature_engine.dart';
import '../models/feature_models.dart';
import '../validation/feature_quality.dart';
import '../validation/feature_validation.dart';

class FeatureModelingApi {
  FeatureModelingApi(this.engine) : builders = FeatureBuilders(engine);
  final FeatureModelingEngine engine;
  final FeatureBuilders builders;
  List<FeatureInstance> get features =>
      List.unmodifiable(engine.features.values);
  void delete(String id) => engine.delete(id);
  void suppress(String id) => engine.suppress(id, true);
  void unsuppress(String id) => engine.suppress(id, false);
  void freeze(String id) => engine.freeze(id, true);
  void unfreeze(String id) => engine.freeze(id, false);
  Future<List<FeatureResult>> rebuild() => engine.rebuildIncremental();
  FeatureValidationResult validate() => engine.validate();
  FeatureQuality quality() => const FeatureQualityEvaluator().evaluate(engine);
  List<FeatureRecommendation> recommendations() =>
      const FeatureAdvisor().analyze(engine);
}
