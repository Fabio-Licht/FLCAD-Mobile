import '../../engineering/learning/engineering_learning.dart';

enum RecognitionFeedback { accepted, rejected, corrected }

class RecognitionLearning {
  RecognitionLearning({EngineeringLearning? learning})
    : learning = learning ?? EngineeringLearning();
  final EngineeringLearning learning;
  final Map<String, List<double>> _thresholds = {};
  Future<void> record({
    required String projectId,
    required String recognitionId,
    required RecognitionFeedback feedback,
    required double confidence,
    String? correction,
  }) async {
    _thresholds.putIfAbsent(feedback.name, () => []).add(confidence);
    await learning.record(
      EngineeringLearningRecord(
        projectId,
        recognitionId,
        'professional-recognition',
        feedback.name,
        DateTime.now(),
        {'confidence': confidence, 'correction': correction},
      ),
    );
  }

  double? learnedThreshold(RecognitionFeedback feedback) {
    final values = _thresholds[feedback.name];
    return values == null || values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
  }
}
