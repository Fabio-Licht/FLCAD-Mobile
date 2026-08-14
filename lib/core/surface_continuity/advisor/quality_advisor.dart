import '../models/surface_continuity_models.dart';

class SurfaceQualityAdvisor {
  const SurfaceQualityAdvisor();
  List<QualityAdvice> advise(
    List<PatchQuality> qualities,
    List<ContinuityAssessment> continuity,
  ) => [
    for (final c in continuity.where((e) => e.level == ContinuityLevel.g0))
      QualityAdvice(
        c.id,
        'Aplicar Match Surface',
        'G0 detectado; nenhuma modificação foi executada.',
      ),
    for (final c in continuity.where(
      (e) => e.level == ContinuityLevel.g1 && e.effective < .8,
    ))
      QualityAdvice(
        c.id,
        'Surface Fair',
        'G1 instável; recomendação consultiva.',
      ),
    for (final q in qualities.where((e) => e.curvature.stability < .7))
      QualityAdvice(
        q.patch.id,
        'Surface Relax',
        'Curvatura oscilante; geometria preservada.',
      ),
    for (final q in qualities.where((e) => e.draft.negative > 0))
      QualityAdvice(
        q.patch.id,
        'Professional Draft Extend',
        'Draft negativo detectado; nenhuma extensão foi aplicada.',
      ),
  ];
}
