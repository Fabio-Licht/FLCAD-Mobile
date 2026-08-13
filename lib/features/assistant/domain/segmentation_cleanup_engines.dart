import 'dart:convert';
import 'dart:io';

import '../../../core/ai/engines/ai_engine.dart';
import '../../../core/ai/models/ai_context.dart';
import '../../../core/ai/models/ai_result.dart';
import '../../../core/ai/models/ai_task.dart';

class SmartSegmentationEngine {
  const SmartSegmentationEngine(this.ai);
  final AIEngine ai;
  Future<AIResult> createAlphaMask(AIContext context) async {
    final result = await ai.execute(
      AIContext(
        projectId: context.projectId,
        projectPath: context.projectPath,
        task: AITask.segmentation,
        input: context.input,
        fingerprint: context.fingerprint,
      ),
    );
    final mask = File(
      '${context.projectPath}/AI/Segmentation/${context.fingerprint.hashCode.toUnsigned(32)}.json',
    );
    await mask.parent.create(recursive: true);
    await mask.writeAsString(
      jsonEncode({
        'type': 'alpha_simple_mask',
        'classes': result.data['classes'],
        'sourceFingerprint': context.fingerprint,
      }),
      flush: true,
    );
    return result;
  }
}

class SmartCleanupEngine {
  const SmartCleanupEngine(this.ai);
  final AIEngine ai;
  Future<AIResult> recommend(AIContext context) => ai.execute(
    AIContext(
      projectId: context.projectId,
      projectPath: context.projectPath,
      task: AITask.cleanup,
      input: context.input,
      fingerprint: context.fingerprint,
    ),
  );
}
