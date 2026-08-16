// ignore_for_file: curly_braces_in_flow_control_structures

import '../../../core/engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../../core/professional_recognition/models/professional_recognition_models.dart';
import '../../../core/smart_reference/api/smart_reference_api.dart';
import '../../../core/smart_reference/models/smart_reference_models.dart';

class SmartReferenceBridge {
  const SmartReferenceBridge(this.api);
  final SmartReferenceApi api;
  SmartReferenceSession analyze({
    required String sessionId,
    required ProfessionalRecognitionReport recognition,
    required EngineeringFeatureSession features,
  }) {
    if (recognition.primitives.isEmpty)
      throw StateError('Recognition produced no primitive evidence.');
    return api.analyze(sessionId: sessionId, features: features);
  }

  SmartReferenceSession approve({
    required String sessionId,
    required String candidateId,
    required String reason,
  }) {
    if (reason.trim().isEmpty)
      throw StateError('Reference approval requires a user reason.');
    return api.accept(sessionId, candidateId, reason);
  }
}
