import '../models/ai_context.dart';
import '../models/ai_result.dart';
import '../models/ai_task.dart';

abstract class AIPlugin {
  String get id;
  String get name;
  String get version;
  int get priority => 0;
  Future<AIResult> execute(AIContext context);
  bool supports(AITask task);
}
