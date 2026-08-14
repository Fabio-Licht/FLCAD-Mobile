import '../graph/feature_graph.dart';
import '../models/feature_models.dart';
import '../validation/feature_validation.dart';

class FeatureDependencyEngine {
  const FeatureDependencyEngine();
  void register(
    FeatureInstance feature,
    Map<String, FeatureInstance> features,
    FeatureGraphSet graphs,
  ) {
    for (final graph in graphs.all) {
      graph.add(feature.id);
    }
    for (final dependency in feature.dependencies) {
      if (!features.containsKey(dependency)) continue;
      graphs.dependencies.connect(dependency, feature.id);
      graphs.execution.connect(dependency, feature.id);
      graphs.parents.connect(dependency, feature.id);
      graphs.children.connect(dependency, feature.id);
      graphs.impact.connect(dependency, feature.id);
    }
  }

  Set<String> downstream(String id, FeatureGraphSet g) =>
      g.dependencies.downstream(id);
  Set<String> upstream(String id, FeatureGraphSet g) =>
      g.dependencies.upstream(id);
  FeatureValidationResult validate(
    Map<String, FeatureInstance> features,
    FeatureGraphSet graphs,
  ) {
    final issues = <FeatureValidationIssue>[];
    for (final f in features.values) {
      for (final d in f.dependencies) {
        final parent = features[d];
        if (parent == null) {
          issues.add(
            FeatureValidationIssue(
              FeatureValidationIssueType.brokenDependency,
              'Missing dependency: $d',
              featureId: f.id,
            ),
          );
        } else if (parent.suppressed) {
          issues.add(
            FeatureValidationIssue(
              FeatureValidationIssueType.suppressedParent,
              'Suppressed parent: $d',
              featureId: f.id,
            ),
          );
        }
      }
    }
    return FeatureValidationResult(issues);
  }
}
