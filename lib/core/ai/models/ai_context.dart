import 'ai_task.dart';

class AIContext {
  const AIContext({
    required this.projectId,
    required this.projectPath,
    required this.task,
    required this.input,
    required this.fingerprint,
  });
  final String projectId;
  final String projectPath;
  final AITask task;
  final Map<String, dynamic> input;
  final String fingerprint;
}
