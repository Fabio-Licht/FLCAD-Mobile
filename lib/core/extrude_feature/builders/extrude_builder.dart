import '../engine/extrude_engine.dart';
import '../models/extrude_models.dart';

class ExtrudeBuilder {
  const ExtrudeBuilder(this.engine);
  final ExtrudeEngine engine;
  ExtrudeFeature build({
    required ExtrudeInput input,
    required ExtrudeParameters parameters,
  }) => engine.prepare(input, parameters);
}
