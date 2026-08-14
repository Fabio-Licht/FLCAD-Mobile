import '../models/transition_models.dart';

class TransitionParameterEngine {
  const TransitionParameterEngine();
  void update(
    TransitionFeature feature,
    void Function(TransitionParameters) change,
  ) {
    change(feature.parameters);
    feature.version++;
    feature.status = TransitionStatus.prepared;
  }
}
