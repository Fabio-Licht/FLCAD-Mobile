import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/reverse_session_api.dart';

class ReverseSessionFelCommand implements FELCommand {
  const ReverseSessionFelCommand(this.name, this.api);
  @override
  final String name;
  final ReverseSessionApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    final id = arguments.isEmpty
        ? api.engine.activeId
        : arguments.first.value.toString();
    Object? value;
    switch (name) {
      case 'SHOW SESSION':
        value = id == null ? null : api.engine.sessions[id]?.toJson();
      case 'SHOW JOURNAL':
        value = id == null
            ? const []
            : api.engine.journal.forSession(id).map((e) => e.toJson()).toList();
      case 'SHOW MILESTONES':
        value = api.engine.milestones.map((e) => e.toJson()).toList();
      case 'SHOW SNAPSHOTS':
        value = api.engine.snapshotManager.snapshots.values
            .map((e) => e.toJson())
            .toList();
      case 'SHOW RECOVERY':
        value = api.engine.recovery.states.values
            .map((e) => e.toJson())
            .toList();
      case 'SHOW SESSION ANALYTICS':
        value = api.engine.analytics.toJson();
      case 'SHOW SESSION HEALTH':
        value = id == null ? const [] : api.engine.recommendations(id);
      case 'SHOW SESSION PROGRESS':
        value = id == null ? 0 : api.engine.sessions[id]?.progress;
      case 'SHOW SESSION TIMELINE':
        value = api.engine.timeline.entries.map((e) => e.toJson()).toList();
      default:
        value = {
          'command': name,
          'status': 'available',
          'automaticCadExecution': false,
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createReverseSessionFelCommands(ReverseSessionApi api) {
  const base = [
    'CREATE SESSION',
    'OPEN SESSION',
    'CLOSE SESSION',
    'SAVE SESSION',
    'RESTORE SESSION',
    'PAUSE SESSION',
    'RESUME SESSION',
    'DELETE SESSION',
    'SHOW SESSION',
    'SHOW JOURNAL',
    'SHOW MILESTONES',
    'SHOW SNAPSHOTS',
    'SHOW RECOVERY',
    'SHOW SESSION ANALYTICS',
    'SHOW SESSION HEALTH',
    'SHOW SESSION PROGRESS',
    'SHOW SESSION TIMELINE',
    'ARCHIVE SESSION',
    'DUPLICATE SESSION',
    'MERGE SESSION',
    'CREATE SNAPSHOT',
    'RESTORE SNAPSHOT',
    'DELETE SNAPSHOT',
    'COMPARE SNAPSHOTS',
    'SHOW CURRENT SNAPSHOT',
    'SHOW SNAPSHOT CONTEXT',
    'SHOW SNAPSHOT WORKFLOW',
    'SHOW SNAPSHOT WORKSPACE',
    'SHOW SNAPSHOT UI',
    'SHOW SNAPSHOT SELECTION',
    'SHOW SNAPSHOT VALIDATION',
    'SHOW SNAPSHOT RECOMMENDATIONS',
    'SHOW SNAPSHOT TIMELINE',
    'CAPTURE RECOVERY',
    'RESTORE RECOVERY',
    'VALIDATE RECOVERY',
    'SHOW RECOVERY DIAGNOSTICS',
    'DELETE RECOVERY',
    'REPLAY SESSION',
    'REPLAY JOURNAL',
    'REPLAY TIMELINE',
    'ADD JOURNAL ENTRY',
    'ADD COMMENT',
    'ADD MILESTONE',
    'SHOW CURRENT MILESTONE',
    'SHOW SESSION DURATION',
    'SHOW TIME BY STEP',
    'SHOW TIME BY WORKSPACE',
    'SHOW SESSION PRODUCTIVITY',
    'SHOW SESSION FEATURES',
    'SHOW SESSION DATUMS',
    'SHOW SESSION ALIGNMENTS',
    'SHOW SESSION VALIDATIONS',
    'SHOW ACCEPTED RECOMMENDATIONS',
    'SHOW IGNORED RECOMMENDATIONS',
    'SHOW SESSION WORKSPACE',
    'SHOW SESSION OVERVIEW',
    'SHOW CURRENT SESSION',
    'SHOW SESSION CONTEXT',
    'SHOW SESSION PROJECT',
    'SHOW SESSION WORKFLOW',
    'SHOW SESSION LAYOUT',
    'SHOW SESSION RIBBON',
    'SHOW SESSION DOCKING',
    'SHOW SESSION VIEWPORT',
    'SHOW SESSION CAMERA',
    'SHOW SESSION SELECTION',
    'SHOW ACTIVE DATUM',
    'SHOW ACTIVE SKETCH',
    'SHOW ACTIVE FEATURE',
    'SHOW SESSION ALIGNMENT',
    'SHOW SESSION VALIDATION',
    'SHOW SESSION HEAT MAP',
    'SHOW ENGINEERING SCORE',
    'SHOW SESSION CHECKLIST',
    'SHOW SESSION ADVISOR',
    'SHOW SESSION UNDO',
    'SHOW SESSION REDO',
    'SHOW INCOMPLETE SESSION',
    'SHOW PENDING VALIDATION',
    'SHOW PENDING ALIGNMENT',
    'SHOW UNVALIDATED FEATURES',
    'SHOW UNUSED SKETCHES',
    'SHOW INTERRUPTED WORKFLOW',
    'EXPORT SESSION',
    'EXPORT JOURNAL',
    'EXPORT TIMELINE',
    'EXPORT SESSION ANALYTICS',
    'IMPORT SESSION',
    'LIST SESSIONS',
    'LIST OPEN SESSIONS',
    'LIST PAUSED SESSIONS',
    'LIST CLOSED SESSIONS',
    'LIST ARCHIVED SESSIONS',
    'FILTER SESSIONS BY USER',
    'FILTER SESSIONS BY PROJECT',
    'FILTER SESSIONS BY STATUS',
    'SORT SESSIONS BY DATE',
    'SORT SESSIONS BY PROGRESS',
    'SORT SESSIONS BY HEALTH',
    'COMPARE SESSIONS',
    'SHOW SESSION CHANGES',
    'SHOW SESSION USERS',
    'SHOW SESSION RESULT',
    'SHOW SESSION COMMENTS',
    'SHOW SESSION EVENTS',
    'SHOW SESSION ACTIVITY',
    'SHOW SESSION HISTORY',
    'SHOW SESSION RECOVERY STATUS',
    'SHOW SESSION SNAPSHOT COUNT',
    'SHOW SESSION MILESTONE COUNT',
    'SHOW SESSION JOURNAL COUNT',
    'SHOW SESSION FEATURE COUNT',
    'SHOW SESSION DATUM COUNT',
    'SHOW SESSION ALIGNMENT COUNT',
    'SHOW SESSION VALIDATION COUNT',
    'SHOW SESSION RECOMMENDATION COUNT',
    'SHOW PROJECT FIRST STATUS',
    'SHOW SESSION LAZY LOADING',
    'SHOW SESSION BOOTSTRAP STATUS',
    'SHOW SESSION KERNEL POLICY',
    'SHOW SESSION CAD EXECUTION STATUS',
    'VALIDATE SESSION',
    'VALIDATE SESSION CONTEXT',
    'VALIDATE SESSION SNAPSHOT',
    'VALIDATE SESSION JOURNAL',
    'VALIDATE SESSION REPLAY',
    'PERSIST SESSION',
    'PERSIST SNAPSHOTS',
    'PERSIST JOURNAL',
    'PERSIST TIMELINE',
    'PERSIST SESSION ANALYTICS',
    'PERSIST RECOVERY',
    'PERSIST MILESTONES',
  ];
  return [for (final name in base) ReverseSessionFelCommand(name, api)];
}
