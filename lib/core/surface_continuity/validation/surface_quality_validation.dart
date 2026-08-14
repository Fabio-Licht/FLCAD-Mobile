import '../models/surface_continuity_models.dart';

class SurfaceQualityValidation {
  const SurfaceQualityValidation();
  List<String> validate(SurfaceQualityReport report) => [
    if (report.patchQualities.any((e) => e.patch.surface.handle == null))
      'Quality entry without native surface',
    if (report.patchQualities.any((e) => e.overall < 0 || e.overall > 1))
      'Quality score outside 0..1',
    if (report.patchQualities.any(
      (e) => e.patch.surface.handle?.type.name == 'solid',
    ))
      'Surface quality must not modify or create solids',
  ];
}
