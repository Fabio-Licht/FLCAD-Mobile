import '../engine/live_validation_engine.dart';
import '../models/validation_models.dart';

class ValidationBuilder {
  const ValidationBuilder(this.engine);
  final LiveValidationEngine engine;
  LiveValidationSession build({
    required ValidationSource source,
    required ValidationSource target,
    ValidationParameters? parameters,
  }) => engine.create(source, target, parameters: parameters);
}
