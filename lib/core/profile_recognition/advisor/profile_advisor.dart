import '../models/profile_models.dart';
import '../validation/profile_validation.dart';

class ProfileAdvisor {
  const ProfileAdvisor();
  List<ProfileRecommendation> advise(ProfileRecognitionOutputView view) {
    final result = <ProfileRecommendation>[];
    if (view.validation.issues.isNotEmpty) {
      result.add(
        ProfileRecommendation(
          title: 'Repair profile topology',
          confidence: 94,
          explanation:
              '${view.validation.issues.length} validation issues prevent reliable downstream modeling',
          impact: 'Improves profile and feature readiness',
          alternatives: const [
            'Add constraints',
            'Repair endpoints',
            'Remove duplicate edges',
          ],
          pros: const ['Stable topology', 'Predictable intent'],
          cons: const ['Requires user review'],
          suggestedAction: 'Inspect highlighted validation issues',
        ),
      );
    }
    if (view.intent.intent == GeometricIntent.unknown ||
        view.intent.confidence < .7) {
      result.add(
        const ProfileRecommendation(
          title: 'Clarify sketch intent',
          confidence: 72,
          explanation: 'The recognized intent has limited evidence',
          impact: 'Improves maintainability and feature preparation',
          alternatives: ['Add construction axes', 'Add dimensions'],
          pros: ['Clearer design intent'],
          cons: ['Additional annotations'],
          suggestedAction: 'Add parametric design cues',
        ),
      );
    }
    return result;
  }
}

class ProfileRecognitionOutputView {
  const ProfileRecognitionOutputView(this.validation, this.intent);
  final ProfileValidationResult validation;
  final IntentRecognition intent;
}
