class SessionAnalytics {
  Duration totalTime = Duration.zero;
  final Map<String, Duration> timeByStep = {}, timeByWorkspace = {};
  int features = 0,
      datums = 0,
      alignments = 0,
      validations = 0,
      acceptedRecommendations = 0,
      ignoredRecommendations = 0,
      snapshots = 0,
      updates = 0;
  void update({
    Duration elapsed = Duration.zero,
    String? step,
    String? workspace,
  }) {
    totalTime += elapsed;
    if (step != null) {
      timeByStep.update(step, (v) => v + elapsed, ifAbsent: () => elapsed);
    }
    if (workspace != null) {
      timeByWorkspace.update(
        workspace,
        (v) => v + elapsed,
        ifAbsent: () => elapsed,
      );
    }
    updates++;
  }

  double get productivity => totalTime.inMinutes == 0
      ? features + datums + alignments + validations.toDouble()
      : (features + datums + alignments + validations) / totalTime.inMinutes;
  Map<String, dynamic> toJson() => {
    'totalTimeMicros': totalTime.inMicroseconds,
    'timeByStep': timeByStep.map((k, v) => MapEntry(k, v.inMicroseconds)),
    'timeByWorkspace': timeByWorkspace.map(
      (k, v) => MapEntry(k, v.inMicroseconds),
    ),
    'features': features,
    'datums': datums,
    'alignments': alignments,
    'validations': validations,
    'acceptedRecommendations': acceptedRecommendations,
    'ignoredRecommendations': ignoredRecommendations,
    'snapshots': snapshots,
    'updates': updates,
    'productivity': productivity,
  };
}
