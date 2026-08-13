import '../models/adaptive_surface.dart';

class SurfaceValidationResult {
  const SurfaceValidationResult(this.valid, this.issues);
  final bool valid;
  final List<String> issues;
}

class SurfaceValidator {
  const SurfaceValidator({this.maximumRms = 1, this.minimumConfidence = .1});
  final double maximumRms, minimumConfidence;
  SurfaceValidationResult validate(AdaptiveSurface s) {
    final issues = <String>[];
    if (s.metrics.rmsError > maximumRms) {
      issues.add('RMS error exceeds tolerance');
    }
    if (s.metrics.confidence < minimumConfidence) {
      issues.add('Confidence below threshold');
    }
    if (s.geometry.toJson().isEmpty) issues.add('Geometry is empty');
    return SurfaceValidationResult(issues.isEmpty, issues);
  }
}
