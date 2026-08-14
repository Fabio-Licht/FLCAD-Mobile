import '../models/surface_recognition_models.dart';

class SurfaceRecognitionValidation {
  const SurfaceRecognitionValidation();
  List<String> validate(SurfaceRecognitionReport report) => [
    if (report.classifications.isEmpty) 'Recognition produced no regions',
    if (report.classifications.any((e) => e.region.triangleIndices.isEmpty))
      'Recognition contains an empty region',
    if (report.analytics.totalArea <= 0) 'Recognition area is invalid',
    if (report.classifications.any((e) => e.confidence < 0 || e.confidence > 1))
      'Confidence is outside 0..1',
  ];
}
