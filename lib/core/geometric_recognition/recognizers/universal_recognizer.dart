import '../models/recognition_models.dart';

abstract interface class UniversalRecognizer {
  String get id;
  PrimitiveType get type;
  bool detect(RecognitionContext context);
  RecognitionCandidate evaluate(RecognitionContext context);
  RecognitionCandidate refine(
    RecognitionContext context,
    RecognitionCandidate candidate,
  );
  bool validate(RecognitionContext context, RecognitionCandidate candidate);
  RecognitionExplanation explain(
    RecognitionContext context,
    RecognitionCandidate candidate,
    List<RecognitionCandidate> alternatives,
  );
  double confidence(RecognitionContext context, RecognitionCandidate candidate);
}

abstract interface class RansacRecognitionContract {
  RecognitionCandidate fit(RecognitionContext context, PrimitiveType type);
}

abstract interface class MEstimatorRecognitionContract {
  List<double> weights(List<double> residuals);
}
