import '../models/recognition_models.dart';

class RecognitionCompetitionResult {
  const RecognitionCompetitionResult(
    this.winner,
    this.alternatives,
    this.rejectedDuplicates,
  );
  final RecognitionCandidate winner;
  final List<RecognitionCandidate> alternatives, rejectedDuplicates;
}

class RecognitionCompetition {
  const RecognitionCompetition();
  RecognitionCompetitionResult resolve(List<RecognitionCandidate> candidates) {
    if (candidates.isEmpty) throw StateError('No recognition candidates');
    final unique = <String, RecognitionCandidate>{},
        duplicates = <RecognitionCandidate>[];
    for (final candidate in candidates) {
      final key = '${candidate.type.name}:${candidate.regionId}';
      final existing = unique[key];
      if (existing == null ||
          candidate.statistics.score > existing.statistics.score) {
        if (existing != null) duplicates.add(existing);
        unique[key] = candidate;
      } else {
        duplicates.add(candidate);
      }
    }
    final ranked = unique.values.toList()
      ..sort((a, b) => b.statistics.score.compareTo(a.statistics.score));
    return RecognitionCompetitionResult(
      ranked.first,
      List.unmodifiable(ranked.skip(1)),
      List.unmodifiable(duplicates),
    );
  }
}
