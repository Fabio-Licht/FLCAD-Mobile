class EngineeringAnalytics {
  const EngineeringAnalytics({
    this.accuracy = 0,
    this.quality = 0,
    this.confidence = 0,
    this.continuity = 0,
    this.metrics = const {},
  });
  final double accuracy, quality, confidence, continuity;
  final Map<String, num> metrics;
  EngineeringAnalytics merge(EngineeringAnalytics other) =>
      EngineeringAnalytics(
        accuracy: (accuracy + other.accuracy) / 2,
        quality: (quality + other.quality) / 2,
        confidence: (confidence + other.confidence) / 2,
        continuity: (continuity + other.continuity) / 2,
        metrics: {...metrics, ...other.metrics},
      );
}
