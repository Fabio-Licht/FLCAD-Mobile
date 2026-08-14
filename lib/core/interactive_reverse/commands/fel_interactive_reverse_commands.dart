import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/interactive_reverse_api.dart';

class InteractiveReverseFelCommand implements FELCommand {
  const InteractiveReverseFelCommand(this.name, this.api);
  @override
  final String name;
  final InteractiveReverseApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    Object? value;
    switch (name) {
      case 'SHOW CONTEXT':
      case 'SHOW RECOMMENDATIONS':
        final id = arguments.isEmpty
            ? api.engine.selectionManager.active.id
            : arguments.first.value.toString();
        value = api.showContext(id);
      case 'SHOW REGION INFO':
      case 'SHOW FEATURE INFO':
        value = api.engine.selectionManager.active.toJson();
      case 'SHOW LOCAL ERROR':
        value = api.engine.selectionManager.active.localError;
      case 'SHOW RELATED FEATURES':
        value = api.engine.selectionManager.active.relatedFeature;
      case 'SHOW DEPENDENCIES':
        value = api.engine.selectionManager.active.dependencies;
      case 'SHOW SELECTION ANALYTICS':
        value = api.engine.analytics.toJson();
      default:
        value = {
          'command': name,
          'status': 'available',
          'automaticExecution': false,
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createInteractiveReverseFelCommands(
  InteractiveReverseApi api,
) {
  const commands = [
    'SELECT REGION',
    'SELECT FEATURE',
    'SELECT DATUM',
    'SELECT MESH REGION',
    'SELECT PLANE',
    'SELECT CYLINDER',
    'SELECT CONE',
    'SELECT SPHERE',
    'SELECT DATUM PLANE',
    'SELECT DATUM AXIS',
    'SELECT DATUM POINT',
    'SELECT SKETCH',
    'SELECT VALIDATION REGION',
    'SELECT CRITICAL REGION',
    'CLEAR SELECTION',
    'SHOW SELECTION',
    'SHOW CONTEXT',
    'SHOW RECOMMENDATIONS',
    'SHOW REGION INFO',
    'SHOW FEATURE INFO',
    'CREATE DATUM FROM SELECTION',
    'CREATE SKETCH FROM SELECTION',
    'OPEN SKETCH FROM SELECTION',
    'EXTRUDE FROM SELECTION',
    'REVOLVE FROM SELECTION',
    'SWEEP FROM SELECTION',
    'LOFT FROM SELECTION',
    'ALIGN FROM SELECTION',
    'VALIDATE SELECTION',
    'REVIEW SELECTION',
    'SHOW LOCAL ERROR',
    'SHOW RELATED FEATURES',
    'SHOW DEPENDENCIES',
    'SHOW SELECTION ANALYTICS',
    'SHOW SELECTION HISTORY',
    'SHOW SELECTION TIMELINE',
    'SHOW SELECTION PREVIEW',
    'SHOW SELECTION HIGHLIGHT',
    'SHOW SELECTION BOUNDS',
    'SHOW SELECTION NORMAL',
    'SHOW SELECTION AREA',
    'SHOW SELECTION RADIUS',
    'SHOW SELECTION CURVATURE',
    'SHOW SELECTION CONFIDENCE',
    'SHOW SELECTION QUALITY',
    'SHOW SELECTION REFERENCES',
    'SHOW WORKFLOW STEP',
    'SHOW CONTEXT ACTIONS',
    'SHOW ADVISOR',
    'ASK REGION IDENTITY',
    'ASK RECOGNITION REASON',
    'ASK FEATURE',
    'ASK DATUM',
    'ASK ALIGNMENT',
    'ASK EXPECTED GAIN',
    'ACCEPT RECOMMENDATION',
    'IGNORE RECOMMENDATION',
    'CANCEL RECOMMENDATION',
    'SHOW PENDING ACTIONS',
    'SHOW ACCEPTED ACTIONS',
    'SHOW IGNORED ACTIONS',
    'SHOW RECOMMENDATION ACCURACY',
    'SHOW AVERAGE SELECTION TIME',
    'SHOW SELECTION TYPES',
    'SHOW USED TOOLS',
    'SHOW INTERACTIVE DASHBOARD',
    'SHOW SELECTED OBJECT',
    'SHOW RECOGNIZED TYPE',
    'SHOW RELATED FEATURE',
    'SHOW DASHBOARD ERROR',
    'SHOW DASHBOARD QUALITY',
    'SHOW DASHBOARD REFERENCES',
    'SHOW DASHBOARD DEPENDENCIES',
    'SHOW DASHBOARD RECOMMENDATION',
    'PERSIST SELECTIONS',
    'PERSIST SELECTION HISTORY',
    'PERSIST SELECTION ANALYTICS',
    'PERSIST SELECTION PREVIEW',
    'PERSIST INTERACTIVE WORKSPACE',
    'PERSIST CONTEXT ACTIONS',
    'SHOW INTERACTIVE WORKSPACE',
    'SHOW SELECTION INSPECTOR',
    'SHOW CONTEXT ACTION PANEL',
    'SHOW INTERACTIVE ADVISOR',
    'SHOW SELECTION ANALYTICS PANEL',
    'REFRESH CONTEXT',
    'REFRESH PREVIEW',
    'REFRESH ADVISOR',
    'REFRESH DASHBOARD',
    'REFRESH TIMELINE',
    'SHOW PLANE ACTIONS',
    'SHOW CYLINDER ACTIONS',
    'SHOW CONE ACTIONS',
    'SHOW SPHERE ACTIONS',
    'SHOW DATUM ACTIONS',
    'SHOW SKETCH ACTIONS',
    'SHOW FEATURE ACTIONS',
    'SHOW VALIDATION ACTIONS',
    'SHOW CRITICAL ACTIONS',
    'SHOW CAUSE',
    'SHOW RESPONSIBLE FEATURE',
    'SHOW CORRECTION SUGGESTION',
    'VALIDATION REPLAY',
    'SHOW ADVANTAGES',
    'SHOW ALTERNATIVES',
    'SHOW EXPLANATION',
    'SHOW EXPECTED GAIN',
    'SHOW INTERACTION STATUS',
    'SHOW INTERACTION DECISION',
    'SHOW INTERACTION INTENT',
    'LIST INTERACTION INTENTS',
    'LIST SELECTIONS',
    'LIST CONTEXT SUGGESTIONS',
    'LIST PREVIEWS',
    'LIST ADVISOR UPDATES',
    'LIST DASHBOARD UPDATES',
    'LIST TIMELINE EVENTS',
    'SHOW PROJECT FIRST STATUS',
    'SHOW LAZY LOADING STATUS',
    'SHOW KERNEL ACCESS POLICY',
    'SHOW AUTOMATIC EXECUTION STATUS',
    'EXPORT SELECTION ANALYTICS',
    'EXPORT SELECTION HISTORY',
    'EXPORT INTERACTION TIMELINE',
    'RESET SELECTION ANALYTICS',
    'FILTER SELECTIONS BY TYPE',
    'FILTER SELECTIONS BY FEATURE',
    'FILTER SELECTIONS BY WORKFLOW',
    'FILTER SELECTIONS BY CONFIDENCE',
    'FILTER SELECTIONS BY ERROR',
    'SORT SELECTIONS BY TIME',
    'SORT SELECTIONS BY QUALITY',
    'SORT SELECTIONS BY ERROR',
    'COMPARE SELECTIONS',
    'COMPARE RECOMMENDATIONS',
    'COMPARE LOCAL ERRORS',
    'SHOW INTERACTIVE VALIDATION',
    'VALIDATE INTERACTION INTENT',
    'VALIDATE SELECTION EVIDENCE',
  ];
  return [for (final name in commands) InteractiveReverseFelCommand(name, api)];
}
