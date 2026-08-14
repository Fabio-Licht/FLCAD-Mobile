class SurfaceMorphAnalytics {
  int operations = 0,
      anchors = 0,
      influencedRegions = 0,
      rollbacks = 0,
      commits = 0,
      cancellations = 0;
  Duration totalTime = Duration.zero;
  Map<String, dynamic> toJson() => {
    'operations': operations,
    'averageMicros': operations == 0
        ? 0
        : totalTime.inMicroseconds ~/ operations,
    'anchors': anchors,
    'influencedRegions': influencedRegions,
    'rollbacks': rollbacks,
    'commits': commits,
    'cancellations': cancellations,
  };
}
