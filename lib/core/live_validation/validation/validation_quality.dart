import '../models/validation_models.dart';

class ValidationQuality {
  const ValidationQuality(this.metrics);
  final ValidationMetrics metrics;
  double get overall => metrics.overallQuality;
}

class ValidationQualityEngine {
  const ValidationQualityEngine();
  ValidationQuality evaluate(LiveValidationSession session) =>
      ValidationQuality(
        session.metrics ?? (throw StateError('Validation metrics unavailable')),
      );
}
