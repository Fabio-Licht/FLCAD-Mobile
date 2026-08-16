import '../../commands/command_dispatcher.dart';
import '../interaction/interaction_context.dart';

class ModelingCommandAdapter {
  const ModelingCommandAdapter(this.dispatcher);
  final CommandDispatcher dispatcher;
  Future<Object?> commit(String commandId, EngineeringPreview preview) =>
      dispatcher.dispatch(commandId, {
        'previewId': preview.id,
        'kind': preview.kind,
        'sourceIds': preview.sourceIds,
        'parameters': preview.parameters,
        'evidence': preview.evidence,
        'confidence': preview.confidence,
        'justification': preview.justification,
        'userConfirmed': true,
      });
}
