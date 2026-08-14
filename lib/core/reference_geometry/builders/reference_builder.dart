import '../engine/reference_engine.dart';
import '../models/reference_models.dart';

class ReferenceBuilder {
  const ReferenceBuilder(this.engine);
  final ReferenceEngine engine;
  ReferenceEntity build({
    required ReferenceType type,
    required ReferenceMethod method,
    required String name,
    ReferenceInput? input,
    ReferenceParameters? parameters,
  }) => engine.create(
    type: type,
    method: method,
    name: name,
    input: input,
    parameters: parameters,
  );
}
