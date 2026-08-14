import '../models/interactive_models.dart';

class InteractiveAnalytics {
  final Map<SelectionType, int> selectionTypes = {};
  final Map<InteractiveOperation, int> toolsUsed = {};
  int suggestions = 0, accepted = 0, ignored = 0, contextChanges = 0;
  Duration totalSelectionTime = Duration.zero;
  void recordSelection(InteractiveSelection selection, Duration elapsed) {
    selectionTypes.update(
      selection.type,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    totalSelectionTime += elapsed;
  }

  void recordSuggestions(int count) => suggestions += count;
  void recordContextChange() => contextChanges++;
  void recordDecision(InteractionIntent intent) {
    if (intent.decision == InteractionDecision.accepted) {
      accepted++;
      toolsUsed.update(
        intent.suggestion.operation,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    } else if (intent.decision == InteractionDecision.ignored) {
      ignored++;
    }
  }

  double get recommendationAccuracy =>
      accepted + ignored == 0 ? 0 : accepted / (accepted + ignored);
  Duration get averageSelectionTime =>
      selectionTypes.values.fold<int>(0, (a, b) => a + b) == 0
      ? Duration.zero
      : totalSelectionTime ~/
            selectionTypes.values.fold<int>(0, (a, b) => a + b);
  Map<String, dynamic> toJson() => {
    'selectionTypes': selectionTypes.map((k, v) => MapEntry(k.name, v)),
    'averageSelectionMicros': averageSelectionTime.inMicroseconds,
    'toolsUsed': toolsUsed.map((k, v) => MapEntry(k.name, v)),
    'suggestions': suggestions,
    'accepted': accepted,
    'ignored': ignored,
    'contextChanges': contextChanges,
    'recommendationAccuracy': recommendationAccuracy,
  };
}
