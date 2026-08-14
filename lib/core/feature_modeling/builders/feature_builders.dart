import '../engine/feature_engine.dart';
import '../models/feature_models.dart';

class FeatureBuilder {
  const FeatureBuilder(this.engine, this.definition);
  final FeatureModelingEngine engine;
  final FeatureDefinition definition;
  FeatureInstance build({
    List<FeatureInput> inputs = const [],
    Map<String, dynamic> parameters = const {},
    List<String> dependencies = const [],
  }) => engine.add(
    FeatureInstance(
      definition: definition,
      inputs: inputs,
      parameters: Map.of(parameters),
      dependencies: List.of(dependencies),
    ),
  );
}

class FeatureBuilders {
  FeatureBuilders(this.engine);
  final FeatureModelingEngine engine;
  FeatureBuilder of(FeatureType type) => FeatureBuilder(
    engine,
    FeatureDefinition(type: type, name: type.name, supported: false),
  );
}
