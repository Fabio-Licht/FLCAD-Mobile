import '../models/surface_fitting_models.dart';

class SurfaceFitAdvisor {
  const SurfaceFitAdvisor();
  List<SurfaceFitAdvice> advise(List<SurfaceEntity> surfaces) => [
    for (final surface in surfaces)
      SurfaceFitAdvice(
        surface.id,
        switch (surface.status) {
          SurfaceFitStatus.notApplicable => 'Enviar para Patch Generation',
          SurfaceFitStatus.rejected => 'Reexecutar fitting',
          SurfaceFitStatus.accepted => 'Aceitar superfície',
        },
        surface.status == SurfaceFitStatus.accepted
            ? 'Residual validado; decisão permanece com o engenheiro.'
            : 'Fitting não aceito; nenhuma geometria substituta foi criada.',
      ),
  ];
}
