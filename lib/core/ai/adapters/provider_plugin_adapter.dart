import '../models/ai_context.dart';
import '../models/ai_result.dart';
import '../models/ai_task.dart';
import '../plugins/ai_plugin.dart';
import '../providers/ai_provider.dart';

class ProviderPluginAdapter extends AIPlugin {
  ProviderPluginAdapter({
    required this.provider,
    required this.modelId,
    required this.modelName,
    required this.modelVersion,
    required Set<AITask> tasks,
    this.adapterPriority = 100,
  }) : _tasks = tasks;
  final AIProvider provider;
  final String modelId;
  final String modelName;
  final String modelVersion;
  final Set<AITask> _tasks;
  final int adapterPriority;
  @override
  String get id => modelId;
  @override
  String get name => modelName;
  @override
  String get version => modelVersion;
  @override
  int get priority => adapterPriority;
  @override
  bool supports(AITask task) => _tasks.contains(task);
  @override
  Future<AIResult> execute(AIContext context) async {
    if (!await provider.isAvailable()) {
      throw StateError('Provider ${provider.id} indisponível');
    }
    return provider.execute(context);
  }
}
