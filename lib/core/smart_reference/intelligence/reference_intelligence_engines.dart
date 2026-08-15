import '../models/smart_reference_models.dart';

class DatumIntelligence {
  const DatumIntelligence();
  List<DatumSuggestion> analyze(
    List<ReferenceCandidate> candidates,
  ) => List.unmodifiable(
    candidates
        .take(3)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => DatumSuggestion(
            label: DatumLabel.values[entry.key],
            referenceId: entry.value.id,
            confidence: entry.value.scores.overallConfidence,
            justification:
                'Datum ${DatumLabel.values[entry.key].name.toUpperCase()} follows deterministic reference ranking position ${entry.key + 1}.',
          ),
        ),
  );
}

class CoordinateSystemIntelligence {
  const CoordinateSystemIntelligence();
  List<CoordinateSystemSuggestion> analyze(
    List<ReferenceCandidate> candidates,
  ) {
    if (candidates.isEmpty) return const [];
    final origins = candidates
        .where((e) => e.category == ReferenceCategory.point)
        .toList();
    final orientations = candidates
        .where(
          (e) =>
              e.category == ReferenceCategory.plane ||
              e.category == ReferenceCategory.axis,
        )
        .toList();
    final systems = candidates
        .where((e) => e.category == ReferenceCategory.coordinateSystem)
        .toList();
    final origin = (origins.isEmpty ? candidates : origins).first;
    final axes = (orientations.isEmpty ? candidates : orientations)
        .take(2)
        .toList();
    final targets = systems.isEmpty ? [candidates.first] : systems;
    return List.unmodifiable(
      targets.map(
        (system) => CoordinateSystemSuggestion(
          referenceId: system.id,
          originReferenceId: origin.id,
          orientationReferenceIds: axes.map((e) => e.id).toList(),
          confidence: system.scores.overallConfidence,
          justification:
              'Best origin and orientations selected by stable reference ranking.',
          alignmentStrategy:
              'Origin → primary orientation → secondary orientation → system',
        ),
      ),
    );
  }
}

class AlignmentStrategyGenerator {
  const AlignmentStrategyGenerator();
  List<AlignmentStrategy> generate(
    String sessionId,
    List<ReferenceCandidate> candidates,
  ) {
    if (candidates.isEmpty) return const [];
    List<ReferenceCandidate> select(List<ReferenceCategory> order) {
      final selected = <ReferenceCandidate>[];
      for (final category in order) {
        final matches = candidates.where(
          (e) => e.category == category && !selected.contains(e),
        );
        if (matches.isNotEmpty) selected.add(matches.first);
      }
      if (selected.isEmpty) selected.add(candidates.first);
      return selected;
    }

    final sequences = [
      select(const [
        ReferenceCategory.plane,
        ReferenceCategory.axis,
        ReferenceCategory.point,
        ReferenceCategory.coordinateSystem,
      ]),
      select(const [
        ReferenceCategory.plane,
        ReferenceCategory.point,
        ReferenceCategory.axis,
        ReferenceCategory.coordinateSystem,
      ]),
      select(const [
        ReferenceCategory.coordinateSystem,
        ReferenceCategory.plane,
        ReferenceCategory.axis,
      ]),
    ];
    return List.unmodifiable(
      sequences.asMap().entries.map((entry) {
        final values = entry.value;
        final confidence =
            values.fold<double>(
              0,
              (sum, e) => sum + e.scores.overallConfidence,
            ) /
            values.length;
        return AlignmentStrategy(
          id: '$sessionId:strategy:${entry.key + 1}',
          steps: values.map((e) => e.id),
          confidence: confidence,
          justification:
              'Strategy ${entry.key + 1} follows an explicit reference-category sequence and stable ranking.',
          evidenceIds: values
              .expand((e) => e.evidence.map((item) => item.id))
              .toSet(),
        );
      }),
    );
  }
}
