class LiveReconstructionAnalytics {
  int pipelines = 0,
      updates = 0,
      rollbacks = 0,
      cancellations = 0,
      commits = 0,
      validationErrors = 0;
  Duration totalUpdateTime = Duration.zero;
  Map<String, dynamic> toJson() => {
    'pipelines': pipelines,
    'updates': updates,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'commits': commits,
    'validationErrors': validationErrors,
    'averageUpdateMicros': updates == 0
        ? 0
        : totalUpdateTime.inMicroseconds ~/ updates,
  };
}
