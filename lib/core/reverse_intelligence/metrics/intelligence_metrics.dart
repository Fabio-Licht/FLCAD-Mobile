class IntelligenceMetrics {
  int analyses = 0, validDecisions = 0;
  Duration elapsed = Duration.zero;
  void record(Duration duration, {required bool valid}) {
    analyses++;
    elapsed += duration;
    if (valid) validDecisions++;
  }

  double get validationRate => analyses == 0 ? 0 : validDecisions / analyses;
}
