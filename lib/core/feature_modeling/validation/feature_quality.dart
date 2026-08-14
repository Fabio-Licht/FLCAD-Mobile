import '../engine/feature_engine.dart';

class FeatureQuality {
  const FeatureQuality(
    this.score,
    this.feature,
    this.dependency,
    this.history,
    this.parameters,
    this.rebuildStability,
    this.maintainability,
  );
  final int score,
      feature,
      dependency,
      history,
      parameters,
      rebuildStability,
      maintainability;
}

class FeatureQualityEvaluator {
  const FeatureQualityEvaluator();
  FeatureQuality evaluate(FeatureModelingEngine e) {
    final invalid = e.validation.issues.length,
        failed = e.features.values
            .where((f) => f.state.name == 'failed')
            .length,
        broken = e.validation.issues
            .where(
              (i) =>
                  i.type.name.contains('Dependency') ||
                  i.type.name.contains('Reference'),
            )
            .length;
    final feature = (100 - invalid * 10).clamp(0, 100),
        dependency = (100 - broken * 15).clamp(0, 100),
        history = (100 - e.analytics.rollbackCount * 2).clamp(0, 100),
        parameters =
            (100 -
                    e.validation.issues
                            .where((i) => i.type.name == 'invalidParameter')
                            .length *
                        10)
                .clamp(0, 100),
        stability = (100 - failed * 20).clamp(0, 100),
        maintainability = ((feature + dependency + parameters) / 3).round(),
        score =
            ((feature +
                        dependency +
                        history +
                        parameters +
                        stability +
                        maintainability) /
                    6)
                .round();
    return FeatureQuality(
      score,
      feature,
      dependency,
      history,
      parameters,
      stability,
      maintainability,
    );
  }
}
