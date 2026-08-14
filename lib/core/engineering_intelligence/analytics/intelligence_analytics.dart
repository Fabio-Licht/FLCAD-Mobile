class IntelligenceAnalytics {
  int projectAnalyses = 0,
      featureAnalyses = 0,
      recommendations = 0,
      diagnostics = 0,
      scoreUpdates = 0,
      healthUpdates = 0,
      timelineUpdates = 0,
      historicalRecords = 0,
      accepted = 0,
      rejected = 0,
      ignored = 0;
  double totalConfidence = 0, observedGain = 0;
  double get averageConfidence =>
      recommendations == 0 ? 0 : totalConfidence / recommendations;
  double get acceptanceRate => accepted + rejected + ignored == 0
      ? 0
      : accepted / (accepted + rejected + ignored);
  Map<String, dynamic> toJson() => {
    'projectAnalyses': projectAnalyses,
    'featureAnalyses': featureAnalyses,
    'recommendations': recommendations,
    'diagnostics': diagnostics,
    'scoreUpdates': scoreUpdates,
    'healthUpdates': healthUpdates,
    'timelineUpdates': timelineUpdates,
    'historicalRecords': historicalRecords,
    'accepted': accepted,
    'rejected': rejected,
    'ignored': ignored,
    'averageConfidence': averageConfidence,
    'acceptanceRate': acceptanceRate,
    'observedGain': observedGain,
  };
}
