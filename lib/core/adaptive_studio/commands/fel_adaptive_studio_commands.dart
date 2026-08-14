import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/adaptive_studio_api.dart';

class AdaptiveStudioFelCommand implements FELCommand {
  const AdaptiveStudioFelCommand(this.name, this.api);
  @override
  final String name;
  final AdaptiveStudioApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    final id = arguments.isEmpty ? '' : arguments.first.value.toString(),
        state = api.engine.workspaces[id];
    Object? result;
    switch (name) {
      case 'SHOW WORKSPACE':
        result = state;
      case 'SHOW DASHBOARD':
        result = state?.dashboard;
      case 'SHOW QUICK ACTIONS':
        result = state?.quickActions;
      case 'SHOW RIBBON':
        result = state?.ribbon;
      case 'SHOW PANELS':
        result = state?.panels.values.toList();
      case 'SHOW LAYOUT':
        result = state?.toJson();
      case 'SHOW RECOMMENDATIONS':
        result = state?.engineeringRecommendation;
      case 'SHOW NAVIGATION':
        result = state?.navigation;
      case 'SHOW RECENT':
        result = state?.navigation.recentObjects;
      case 'SHOW FAVORITES':
        result = state?.navigation.favorites;
      case 'SHOW PINNED':
        result = state?.navigation.pinnedObjects;
      case 'SHOW DOCKS':
        result = state?.panels.map((k, v) => MapEntry(k, v.dockState.name));
      case 'SHOW WORKSPACE ANALYTICS':
        result = api.engine.analytics.toJson();
      default:
        result = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createAdaptiveStudioFelCommands(AdaptiveStudioApi api) {
  const base = [
    'SHOW WORKSPACE',
    'CHANGE WORKSPACE',
    'SHOW DASHBOARD',
    'SHOW QUICK ACTIONS',
    'SHOW RIBBON',
    'SHOW PANELS',
    'SHOW LAYOUT',
    'SAVE LAYOUT',
    'RESTORE LAYOUT',
    'RESET LAYOUT',
    'FOCUS MODE',
    'MAXIMUM VIEWPORT',
    'MINIMAL UI',
    'SKETCH FOCUS',
    'VALIDATION FOCUS',
    'MODELING FOCUS',
    'PRESENTATION MODE',
    'SHOW ALL TOOLS',
    'SHOW RELEVANT TOOLS',
    'SHOW RECOMMENDATIONS',
    'SHOW NAVIGATION',
    'SHOW RECENT',
    'SHOW RECENT OBJECTS',
    'SHOW RECENT FEATURES',
    'SHOW RECENT REFERENCES',
    'SHOW FAVORITES',
    'SHOW PINNED',
    'SHOW DOCKS',
    'DOCK PANEL',
    'UNDOCK PANEL',
    'AUTO HIDE PANEL',
    'PIN PANEL',
    'FLOAT PANEL',
    'SNAP PANEL',
    'RESTORE DOCKING',
    'SHOW WORKSPACE ANALYTICS',
    'SHOW WORKSPACE HISTORY',
    'SHOW NOTIFICATIONS',
    'SHOW SUCCESS NOTIFICATIONS',
    'SHOW WARNING NOTIFICATIONS',
    'SHOW CRITICAL NOTIFICATIONS',
    'SHOW RECOMMENDATION NOTIFICATIONS',
    'MARK NOTIFICATION READ',
    'SHOW WORKFLOW PROGRESS',
    'SHOW CURRENT STEP',
    'SHOW PROJECT HEALTH',
    'SHOW ENGINEERING SCORE',
    'SHOW RECOGNITION STATUS',
    'SHOW ALIGNMENT STATUS',
    'SHOW VALIDATION STATUS',
    'SHOW HEATMAP STATUS',
    'SHOW CURRENT FEATURE',
    'SHOW CHECKLIST',
    'SHOW TIMELINE',
    'SHOW CURRENT QUICK ACTION',
    'SHOW ENGINEERING RECOMMENDATION',
    'USE QUICK ACTION',
    'SHOW IMPORT WORKSPACE',
    'SHOW RECOGNITION WORKSPACE',
    'SHOW REFERENCE WORKSPACE',
    'SHOW ALIGNMENT WORKSPACE',
    'SHOW VALIDATION WORKSPACE',
    'SHOW SKETCH WORKSPACE',
    'SHOW CONSTRAINT WORKSPACE',
    'SHOW PROFILE WORKSPACE',
    'SHOW FEATURE WORKSPACE',
    'SHOW REVIEW WORKSPACE',
    'SHOW FINALIZATION WORKSPACE',
    'SHOW RECOGNITION RIBBON',
    'SHOW ALIGNMENT RIBBON',
    'SHOW SKETCH RIBBON',
    'SHOW VALIDATION RIBBON',
    'SHOW FEATURE RIBBON',
    'UPDATE DASHBOARD',
    'VISIT OBJECT',
    'FAVORITE OBJECT',
    'UNFAVORITE OBJECT',
    'PIN OBJECT',
    'UNPIN OBJECT',
    'PERSIST WORKSPACE',
    'SHOW WORKSPACE MEMORY',
    'DELETE WORKSPACE MEMORY',
    'SHOW MULTI MONITOR STATE',
    'MOVE PANEL TO MONITOR',
    'SHOW PANEL USAGE',
    'SHOW QUICK ACTION USAGE',
    'SHOW RIBBON USAGE',
    'SHOW FOCUS USAGE',
    'SHOW LAYOUT CHANGES',
    'SHOW DOCKING CHANGES',
    'SHOW WORKSPACE TIME',
    'SHOW ADAPTIVE STUDIO',
    'SHOW PROGRESSIVE DISCLOSURE',
    'ENABLE PROGRESSIVE DISCLOSURE',
    'DISABLE PROGRESSIVE DISCLOSURE',
    'SHOW WORKSPACE FILTERS',
    'SHOW WORKSPACE COLUMNS',
    'SET WORKSPACE FILTER',
    'SET WORKSPACE COLUMNS',
    'SHOW BOOTSTRAP STATUS',
  ];
  return [for (final name in base) AdaptiveStudioFelCommand(name, api)];
}
