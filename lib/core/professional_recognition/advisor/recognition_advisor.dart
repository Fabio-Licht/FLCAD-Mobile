import '../models/professional_recognition_models.dart';

class RecognitionAdvisor {
  const RecognitionAdvisor();
  List<ActiveRecognitionAdvice> advise(ProfessionalRecognitionReport report) {
    final advice = <ActiveRecognitionAdvice>[];
    if (report.recognizedCoverage < .7) {
      advice.add(
        const ActiveRecognitionAdvice(
          'Aumentar cobertura',
          'A cobertura reconhecida está abaixo de 70%.',
          .9,
        ),
      );
    }
    if (report.pendingRegionIds.isNotEmpty) {
      advice.add(
        const ActiveRecognitionAdvice(
          'Girar a peça e escanear novamente',
          'Há regiões sem classificação geométrica validada.',
          .85,
        ),
      );
    }
    if (report.primitives.any(
      (p) => p.recognition.winner.statistics.stability < .6,
    )) {
      advice.add(
        const ActiveRecognitionAdvice(
          'Melhorar resolução',
          'Existem ajustes geometricamente instáveis.',
          .75,
        ),
      );
    }
    return advice;
  }
}
