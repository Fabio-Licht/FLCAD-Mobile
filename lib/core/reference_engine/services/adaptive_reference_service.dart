import '../models/reference_entity.dart';

class AdaptiveReferenceDecision {
  const AdaptiveReferenceDecision(
    this.shouldRebuild,
    this.reason,
    this.expectedConfidence,
  );
  final bool shouldRebuild;
  final String reason;
  final double expectedConfidence;
}

class AdaptiveReferenceService {
  const AdaptiveReferenceService();
  AdaptiveReferenceDecision evaluate(
    ReferenceEntity current, {
    required String newSourceFingerprint,
    required double newSourceConfidence,
  }) {
    if (current.mode != ReferenceMode.live) {
      return AdaptiveReferenceDecision(
        false,
        'Referência estática',
        current.analytics.confidence,
      );
    }
    if (newSourceFingerprint == current.dna.sourceFingerprint) {
      return AdaptiveReferenceDecision(
        false,
        'Geometria inalterada',
        current.analytics.confidence,
      );
    }
    if (newSourceConfidence > current.analytics.confidence) {
      return AdaptiveReferenceDecision(
        true,
        'Nova geometria possui maior confiança',
        newSourceConfidence,
      );
    }
    return AdaptiveReferenceDecision(
      false,
      'Nova solução não é mais robusta',
      current.analytics.confidence,
    );
  }
}
