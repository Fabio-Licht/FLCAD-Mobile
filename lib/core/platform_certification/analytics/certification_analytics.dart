class CertificationAnalytics {
  int certifications = 0,
      demonstrations = 0,
      sessions = 0,
      restores = 0,
      validations = 0,
      replays = 0,
      dashboards = 0,
      quickActions = 0,
      selections = 0,
      reviews = 0;
  Map<String, dynamic> toJson() => {
    'certifications': certifications,
    'demonstrations': demonstrations,
    'sessions': sessions,
    'restores': restores,
    'validations': validations,
    'replays': replays,
    'dashboards': dashboards,
    'quickActions': quickActions,
    'selections': selections,
    'reviews': reviews,
  };
}
