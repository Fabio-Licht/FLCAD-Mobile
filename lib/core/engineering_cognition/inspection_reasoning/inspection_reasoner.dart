import '../models/cognition_models.dart';

class InspectionCognitionReasoner {
  const InspectionCognitionReasoner();
  List<InspectionAssessment> reason(
    List<RecognizedFeature> features,
    List<EngineeringIntent> intents,
  ) {
    final result = <InspectionAssessment>[];
    for (final f in features) {
      final role = switch (f.kind) {
        'seat' => 'probableDatumOrCriticalDiameter',
        'hole' || 'thread' => 'positionAndSize',
        'flange' => 'probableDatumPlane',
        'guide' => 'orientationAndProfile',
        _ => 'functionalSurfaceReview',
      };
      result.add(
        InspectionAssessment(
          f.id,
          role,
          f.confidence * .8,
          '${f.kind} and its inferred function indicate an inspection candidate; actual datum and tolerance require design authority.',
        ),
      );
    }
    return result;
  }
}
