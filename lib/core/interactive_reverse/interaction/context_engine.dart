import '../models/interactive_models.dart';

class ContextEngine {
  const ContextEngine();

  List<ContextSuggestion> suggestionsFor(InteractiveSelection selection) {
    final operations = switch (selection.type) {
      SelectionType.recognizedPlane => const [
        InteractiveOperation.createDatum,
        InteractiveOperation.createSketch,
        InteractiveOperation.alignment,
        InteractiveOperation.validation,
      ],
      SelectionType.recognizedCylinder => const [
        InteractiveOperation.createDatum,
        InteractiveOperation.alignment,
        InteractiveOperation.revolve,
        InteractiveOperation.validation,
      ],
      SelectionType.criticalRegion => const [
        InteractiveOperation.showCause,
        InteractiveOperation.engineeringReview,
        InteractiveOperation.validationReplay,
      ],
      SelectionType.recognizedCone || SelectionType.recognizedSphere => const [
        InteractiveOperation.createDatum,
        InteractiveOperation.alignment,
        InteractiveOperation.validation,
      ],
      SelectionType.datumPlane => const [
        InteractiveOperation.createSketch,
        InteractiveOperation.alignment,
      ],
      SelectionType.datumAxis => const [
        InteractiveOperation.revolve,
        InteractiveOperation.alignment,
      ],
      SelectionType.datumPoint => const [InteractiveOperation.alignment],
      SelectionType.sketch => const [
        InteractiveOperation.openSketch,
        InteractiveOperation.extrude,
        InteractiveOperation.revolve,
        InteractiveOperation.sweep,
        InteractiveOperation.loft,
      ],
      SelectionType.feature => const [
        InteractiveOperation.engineeringReview,
        InteractiveOperation.validation,
      ],
      SelectionType.meshRegion || SelectionType.validationRegion => const [
        InteractiveOperation.createDatum,
        InteractiveOperation.validation,
        InteractiveOperation.engineeringReview,
      ],
    };
    return [for (final operation in operations) _build(operation, selection)];
  }

  ContextSuggestion _build(
    InteractiveOperation operation,
    InteractiveSelection selection,
  ) => ContextSuggestion(
    operation: operation,
    label: _label(operation),
    command: _command(operation),
    confidence: selection.confidence,
    explanation:
        '${selection.type.name} supports ${_label(operation).toLowerCase()} at ${selection.workflowStep}.',
    advantages: const ['Uses the selected evidence', 'Preserves Project First'],
    alternatives: const ['Inspect selection', 'Ignore recommendation'],
    expectedGain: (selection.confidence * (1 - selection.localError)).clamp(
      0,
      1,
    ),
  );

  String _label(InteractiveOperation operation) => switch (operation) {
    InteractiveOperation.createDatum => 'Create Datum',
    InteractiveOperation.createSketch => 'Create Sketch',
    InteractiveOperation.openSketch => 'Open Sketch',
    InteractiveOperation.extrude => 'Extrude',
    InteractiveOperation.revolve => 'Revolve',
    InteractiveOperation.sweep => 'Sweep',
    InteractiveOperation.loft => 'Loft',
    InteractiveOperation.alignment => 'Alignment',
    InteractiveOperation.validation => 'Validation',
    InteractiveOperation.engineeringReview => 'Engineering Review',
    InteractiveOperation.showCause => 'Show Cause',
    InteractiveOperation.validationReplay => 'Validation Replay',
  };

  String _command(InteractiveOperation operation) =>
      _label(operation).toUpperCase().replaceAll(' ', '_');
}
