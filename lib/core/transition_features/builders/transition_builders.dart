import '../engine/transition_engine.dart';
import '../models/transition_models.dart';

class SweepBuilder {
  const SweepBuilder(this.engine);
  final TransitionEngine engine;
  TransitionFeature build({
    required TransitionInput input,
    required TransitionParameters parameters,
  }) => engine.prepare(TransitionFamily.sweep, input, parameters);
}

class LoftBuilder {
  const LoftBuilder(this.engine);
  final TransitionEngine engine;
  TransitionFeature build({
    required TransitionInput input,
    required TransitionParameters parameters,
  }) => engine.prepare(TransitionFamily.loft, input, parameters);
}
