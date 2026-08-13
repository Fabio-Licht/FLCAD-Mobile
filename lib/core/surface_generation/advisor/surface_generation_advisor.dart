import '../models/surface_generation_models.dart';

class SurfaceGenerationAdvisor {
  const SurfaceGenerationAdvisor();
  SurfaceGenerationAdvice explain(
    GeneratedSurface surface, {
    required double predictedQuality,
  }) => SurfaceGenerationAdvice(
    surfaceId: surface.surfaceId,
    why:
        'Created as ${surface.kind.name} from approved Surface Intelligence evidence for regions ${surface.regionIds.join(', ')}.',
    evidenceIds: surface.evidenceIds,
    predictedQuality: predictedQuality,
    limitations: [
      if (surface.diagnostics.isNotEmpty) 'Kernel diagnostics require review',
      if (surface.continuity.name == 'g0')
        'Only positional continuity is predicted',
    ],
    improvements: [
      if (surface.diagnostics.isNotEmpty) 'Review healing and repair proposals',
      'Compare result against the source region before downstream features',
    ],
  );
}
