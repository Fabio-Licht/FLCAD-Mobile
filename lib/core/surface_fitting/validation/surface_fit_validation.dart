import '../models/surface_fitting_models.dart';

class SurfaceFitValidation {
  const SurfaceFitValidation();
  List<String> validateCandidate(SurfaceFitCandidate candidate) => [
    if (!candidate.residuals.rms.isFinite) 'Residual RMS is not finite',
    if (!candidate.residuals.maximum.isFinite) 'Residual maximum is not finite',
    if (candidate.confidence < 0 || candidate.confidence > 1)
      'Confidence is outside 0..1',
    if (candidate.parameters.values.any((v) => v is double && !v.isFinite))
      'A fitted parameter is not finite',
  ];
  List<String> validateReport(SurfaceFittingReport report) => [
    if (report.surfaces
        .where((e) => e.status == SurfaceFitStatus.accepted)
        .any((e) => e.handle == null))
      'Accepted surface without native handle',
    if (report.surfaces
        .where((e) => e.handle != null)
        .any((e) => e.handle!.kernelId == 'none'))
      'Surface uses unavailable kernel',
  ];
}
