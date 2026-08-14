import '../advisor/reverse_advisor.dart';
import '../analytics/interactive_analytics.dart';
import '../history/interactive_history.dart';
import '../interaction/context_engine.dart';
import '../models/interactive_models.dart';
import '../recognition/selection_preview.dart';
import '../repository/interactive_reverse_repository.dart';
import '../selection/selection_manager.dart';
import '../validation/interactive_validation.dart';

class InteractiveReverseEngine {
  InteractiveReverseEngine({required this.repository});
  final InteractiveReverseRepository repository;
  final SelectionManager selectionManager = SelectionManager();
  final ContextEngine contextEngine = const ContextEngine();
  final SelectionPreviewEngine previewEngine = const SelectionPreviewEngine();
  final ReverseAdvisor advisor = const ReverseAdvisor();
  final InteractiveValidation validation = const InteractiveValidation();
  final InteractiveAnalytics analytics = InteractiveAnalytics();
  final InteractiveHistory history = InteractiveHistory();
  final InteractiveTimeline timeline = InteractiveTimeline();
  final InteractiveDashboardState dashboard = InteractiveDashboardState();
  final Map<String, SelectionPreview> previews = {};
  final Map<String, List<ContextSuggestion>> suggestions = {};
  final Map<String, InteractionIntent> intents = {};
  final Map<String, AdvisorResponse> advice = {};

  InteractiveSelection select(InteractiveSelection selection) {
    final started = DateTime.now();
    final errors = validation.validate(selection);
    if (errors.isNotEmpty) throw StateError(errors.join('; '));
    selectionManager.select(selection);
    previews[selection.id] = previewEngine.create(selection);
    final context = contextEngine.suggestionsFor(selection);
    suggestions[selection.id] = context;
    advice[selection.id] = advisor.advise(selection, context);
    _updateDashboard(selection, context.first);
    analytics.recordSelection(selection, DateTime.now().difference(started));
    analytics.recordSuggestions(context.length);
    _record('selection', selection.id, selection.workflowStep, 'selected');
    return selection;
  }

  List<ContextSuggestion> changeContext(String selectionId) {
    final selection =
        selectionManager.selections[selectionId] ??
        (throw StateError('Unknown selection: $selectionId'));
    final context = contextEngine.suggestionsFor(selection);
    suggestions[selectionId] = context;
    advice[selectionId] = advisor.advise(selection, context);
    _updateDashboard(selection, context.first);
    analytics.recordContextChange();
    _record('context', selection.id, selection.workflowStep, 'updated');
    return List.unmodifiable(context);
  }

  InteractionIntent requestAction(String selectionId, String suggestionId) {
    final suggestion =
        suggestions[selectionId]
            ?.where((item) => item.id == suggestionId)
            .firstOrNull ??
        (throw StateError('Unknown context suggestion: $suggestionId'));
    final intent = InteractionIntent(
      selectionId: selectionId,
      suggestion: suggestion,
    );
    intents[intent.id] = intent;
    _record(
      'suggestion',
      intent.id,
      selectionManager.selections[selectionId]!.workflowStep,
      'pending',
    );
    return intent;
  }

  void decide(String intentId, InteractionDecision decision) {
    final intent =
        intents[intentId] ??
        (throw StateError('Unknown interaction intent: $intentId'));
    if (intent.decision != InteractionDecision.pending) {
      throw StateError('Interaction intent already decided: $intentId');
    }
    if (decision == InteractionDecision.pending) {
      throw ArgumentError.value(decision, 'decision');
    }
    intent.decision = decision;
    analytics.recordDecision(intent);
    final selection = selectionManager.selections[intent.selectionId]!;
    _record('decision', intent.id, selection.workflowStep, decision.name);
  }

  void _updateDashboard(
    InteractiveSelection selection,
    ContextSuggestion suggestion,
  ) {
    dashboard
      ..selectedObject = selection.objectId
      ..recognizedType = selection.type.name
      ..quality = selection.quality
      ..error = selection.localError
      ..relatedFeature = selection.relatedFeature;
    dashboard.references
      ..clear()
      ..addAll(selection.references);
    dashboard.dependencies
      ..clear()
      ..addAll(selection.dependencies);
    dashboard.recommendation = suggestion.label;
  }

  void _record(String kind, String id, String step, String result) {
    history.add(
      InteractiveHistoryEntry(
        kind: kind,
        subjectId: id,
        workflowStep: step,
        result: result,
      ),
    );
    timeline.add(
      InteractiveHistoryEntry(
        kind: kind,
        subjectId: id,
        workflowStep: step,
        result: result,
      ),
    );
  }

  Future<void> persist() => repository.save(
    selections: selectionManager.selections.values,
    previews: previews.values,
    intents: intents.values,
    history: history,
    timeline: timeline,
    analytics: analytics,
    dashboard: dashboard,
  );
}
