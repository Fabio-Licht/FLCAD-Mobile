class ProfileAnalytics {
  int profiles = 0,
      loops = 0,
      regions = 0,
      recognitionCount = 0,
      totalRecognitionMicros = 0,
      advisorUsage = 0,
      intentDetections = 0;
  double averageComplexity = 0;
  int quality = 0;
  final Map<String, int> readiness = {};
  double get averageRecognitionTimeMicros =>
      recognitionCount == 0 ? 0 : totalRecognitionMicros / recognitionCount;
  Map<String, dynamic> toJson() => {
    'profiles': profiles,
    'loops': loops,
    'regions': regions,
    'averageComplexity': averageComplexity,
    'recognitionTimeMicros': averageRecognitionTimeMicros,
    'quality': quality,
    'advisorUsage': advisorUsage,
    'readiness': readiness,
    'intentDetection': intentDetections,
  };
}
