import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../reverse_intelligence/brain/reverse_brain.dart';
import '../api/engineering_knowledge_api.dart';
import '../datasets/knowledge_dataset.dart';
import '../learning/knowledge_learning.dart';
import '../serialization/knowledge_serialization.dart';

class KnowledgeFELCommand implements FELCommand {
  KnowledgeFELCommand(this.name, this.action, this.api, this.learning);
  @override
  final String name;
  final String action;
  final EngineeringKnowledgeApi api;
  final KnowledgeLearningEngine learning;
  @override
  List<FELType> get argumentTypes => switch (action) {
    'export' || 'reason' || 'infer' => const [],
    _ => const [FELType.string],
  };
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object value;
    FELType type = FELType.dynamicType;
    switch (action) {
      case 'load':
        final dataset = const KnowledgeDatasetCodec().decode(
          args.first.value as String,
        );
        api.load(dataset);
        value = dataset;
      case 'query':
        value = api.query(args.first.value as String);
      case 'explainFeature':
        value =
            api.explain(args.first.value as String) ??
            (throw StateError('Unknown feature knowledge'));
      case 'explainManufacturing':
        value =
            api.explain(args.first.value as String) ??
            (throw StateError('Unknown manufacturing knowledge'));
      case 'suggestFeature':
        value = api
            .query(args.first.value as String)
            .where((c) => c.kind == 'feature')
            .toList();
      case 'suggestProcess':
        value = api
            .query(args.first.value as String)
            .where((c) => c.kind == 'manufacturingProcess')
            .toList();
      case 'reason' || 'infer':
        final arei = context.variables['AREI_LAST']?.value;
        if (arei is! ReverseBrainResult) {
          throw StateError('ANALYZE MESH must be executed first');
        }
        value = api.inferArei(arei.twin);
      case 'learn':
        final assertion = args.first.value as String;
        await learning.learn(
          EngineeringLearningSample(
            context.projectId,
            context.activeMesh?.id ?? 'project',
            assertion,
            true,
            DateTime.now().toUtc(),
            const {'source': 'FEL'},
          ),
        );
        value = assertion;
        type = FELType.string;
      case 'export':
        value = const KnowledgeSerialization().exportConcepts(
          api.library.entries,
        );
        type = FELType.string;
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(type, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createKnowledgeFELCommands() {
  final api = EngineeringKnowledgeApi(),
      learning = KnowledgeLearningEngine(InMemoryKnowledgeLearningStore());
  return [
    KnowledgeFELCommand('LOAD KNOWLEDGE', 'load', api, learning),
    KnowledgeFELCommand('QUERY KNOWLEDGE', 'query', api, learning),
    KnowledgeFELCommand('EXPLAIN FEATURE', 'explainFeature', api, learning),
    KnowledgeFELCommand(
      'EXPLAIN MANUFACTURING',
      'explainManufacturing',
      api,
      learning,
    ),
    KnowledgeFELCommand('SUGGEST FEATURE', 'suggestFeature', api, learning),
    KnowledgeFELCommand('SUGGEST PROCESS', 'suggestProcess', api, learning),
    KnowledgeFELCommand('REASON', 'reason', api, learning),
    KnowledgeFELCommand('INFER', 'infer', api, learning),
    KnowledgeFELCommand('LEARN ENGINEERING', 'learn', api, learning),
    KnowledgeFELCommand('EXPORT KNOWLEDGE', 'export', api, learning),
  ];
}
