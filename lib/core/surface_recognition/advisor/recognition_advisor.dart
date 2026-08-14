import '../../geometric_recognition/models/recognition_models.dart';
import '../models/surface_recognition_models.dart';

class SurfaceRecognitionAdvisor {
  const SurfaceRecognitionAdvisor();
  List<RecognitionAdvice> advise(List<SurfaceClassification> values) => [
    for (final value in values)
      RecognitionAdvice(
        value.region.id,
        switch (value.type) {
          PrimitiveType.plane => 'Criar Datum Plane',
          PrimitiveType.cylinder ||
          PrimitiveType.cone ||
          PrimitiveType.torus => 'Criar Datum Axis',
          PrimitiveType.sphere => 'Criar Datum Point',
          PrimitiveType.freeform => 'Iniciar Surface Reconstruction',
          _ => 'Revisar região manualmente',
        },
        'Sugestão consultiva baseada em ${value.type.name}; nenhuma ação foi executada.',
      ),
  ];
}
