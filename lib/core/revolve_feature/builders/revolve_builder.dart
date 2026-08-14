import '../engine/revolve_engine.dart';
import '../models/revolve_models.dart';

class RevolveBuilder {
  const RevolveBuilder(this.engine);
  final RevolveEngine engine;
  RevolveFeature build({
    required RevolveInput input,
    required RevolveParameters parameters,
  }) => engine.prepare(input, parameters);
}
