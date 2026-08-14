import '../engine/interactive_reverse_engine.dart';
import '../models/interactive_models.dart';

class InteractiveReverseApi {
  const InteractiveReverseApi(this.engine);
  final InteractiveReverseEngine engine;
  InteractiveSelection select(InteractiveSelection selection) =>
      engine.select(selection);
  List<ContextSuggestion> showContext(String selectionId) =>
      engine.changeContext(selectionId);
  InteractionIntent requestAction(String selectionId, String suggestionId) =>
      engine.requestAction(selectionId, suggestionId);
  void decide(String intentId, InteractionDecision decision) =>
      engine.decide(intentId, decision);
  Future<void> persist() => engine.persist();
}
