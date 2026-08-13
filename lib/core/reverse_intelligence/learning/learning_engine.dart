import '../../engineering/learning/engineering_learning.dart';
import '../memory/engineering_memory.dart';

class ReverseLearningEngine {
  const ReverseLearningEngine(this.memory, this.platformLearning);
  final EngineeringMemory memory;
  final EngineeringLearning platformLearning;
  Future<void> learnCorrection({
    required String projectId,
    required String meshSignature,
    required String strategyId,
    required String correction,
  }) async {
    final now = DateTime.now().toUtc();
    await memory.remember(
      EngineeringExperience(
        projectId: projectId,
        meshSignature: meshSignature,
        strategyId: strategyId,
        outcome: 'corrected',
        recordedAt: now,
        correction: correction,
      ),
    );
    await platformLearning.record(
      EngineeringLearningRecord(
        projectId,
        meshSignature,
        'reverse_intelligence',
        'correction',
        now,
        {'strategyId': strategyId, 'correction': correction},
      ),
    );
  }
}
