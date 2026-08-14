import '../models/surface_recognition_models.dart';

class SurfaceConfidenceEngine {
  const SurfaceConfidenceEngine();
  RecognitionHealth health(double confidence) => switch (confidence) {
    >= .90 => RecognitionHealth.excellent,
    >= .75 => RecognitionHealth.good,
    >= .55 => RecognitionHealth.medium,
    >= .35 => RecognitionHealth.low,
    _ => RecognitionHealth.rejected,
  };
}
