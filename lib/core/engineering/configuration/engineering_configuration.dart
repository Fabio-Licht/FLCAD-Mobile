class EngineeringConfiguration {
  const EngineeringConfiguration({
    this.releaseMode = false,
    this.cloudEnabled = false,
    this.metricsEnabled = true,
    this.preferences = const {},
  });
  final bool releaseMode, cloudEnabled, metricsEnabled;
  final Map<String, dynamic> preferences;
}
