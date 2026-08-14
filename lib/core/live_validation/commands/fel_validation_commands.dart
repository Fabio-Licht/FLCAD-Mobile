import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/live_validation_api.dart';

class LiveValidationFelCommand implements FELCommand {
  const LiveValidationFelCommand(this.name, this.api);
  @override
  final String name;
  final LiveValidationApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    final id = arguments.isEmpty ? '' : arguments.first.value.toString();
    Object? result;
    switch (name) {
      case 'START LIVE VALIDATION':
        result = await api.start(id);
      case 'STOP LIVE VALIDATION':
        api.stop(id);
      case 'PAUSE VALIDATION':
        api.pause(id);
      case 'RESUME VALIDATION':
        api.resume(id);
      case 'SHOW HEATMAP':
        result = api.heatMap(id);
      case 'SHOW RMS':
        result = api.engine.sessions[id]?.metrics?.rms;
      case 'SHOW MAX ERROR':
        result = api.engine.sessions[id]?.metrics?.maximumDeviation;
      case 'SHOW AVERAGE ERROR':
        result = api.engine.sessions[id]?.metrics?.averageDeviation;
      case 'SHOW TOLERANCE':
        result = api.engine.sessions[id]?.parameters.tolerance;
      case 'SHOW CRITICAL REGIONS':
        result = api.heatMap(id).criticalRegions;
      case 'SHOW VALIDATION QUALITY':
        result = api.quality(id);
      case 'SHOW VALIDATION HISTORY':
        result = api.engine.history.entries;
      case 'SHOW VALIDATION TIMELINE':
        result = api.engine.timeline.entries;
      case 'SHOW VALIDATION ANALYTICS':
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

List<FELCommand> createLiveValidationFelCommands(LiveValidationApi api) => [
  for (final name in const [
    'START LIVE VALIDATION',
    'STOP LIVE VALIDATION',
    'PAUSE VALIDATION',
    'RESUME VALIDATION',
    'SHOW HEATMAP',
    'SHOW RMS',
    'SHOW MAX ERROR',
    'SHOW AVERAGE ERROR',
    'SHOW TOLERANCE',
    'SHOW CRITICAL REGIONS',
    'SHOW WARNING REGIONS',
    'SHOW VALIDATION QUALITY',
    'SHOW VALIDATION HISTORY',
    'SHOW VALIDATION TIMELINE',
    'SHOW VALIDATION ANALYTICS',
    'COMPARE SNAPSHOTS',
    'CREATE SNAPSHOT',
    'CREATE BASELINE',
    'RESTORE BASELINE',
    'REPLAY VALIDATION',
    'ROLLBACK VALIDATION',
    'VALIDATE SESSION',
    'SHOW VALIDATION',
    'SHOW VALIDATIONS',
    'SHOW VALIDATION STATUS',
    'SHOW VALIDATION SOURCE',
    'SHOW VALIDATION TARGET',
    'SHOW VALIDATION CONFIDENCE',
    'SHOW STANDARD DEVIATION',
    'SHOW WITHIN TOLERANCE',
    'SHOW OUTSIDE TOLERANCE',
    'SHOW CRITICAL AREA',
    'SHOW VALIDATION STABILITY',
    'SHOW VALIDATION PROGRESS',
    'SHOW VALIDATION ADVISOR',
    'SHOW NEXT FEATURE SUGGESTION',
    'SHOW DATUM SUGGESTION',
    'SHOW ALIGNMENT SUGGESTION',
    'SHOW ERROR CAUSES',
    'SHOW CORRECTION PRIORITY',
    'SHOW EXPECTED IMPROVEMENT',
    'SHOW VALIDATION ALTERNATIVES',
    'UPDATE VALIDATION REGION',
    'UPDATE VALIDATION FEATURE',
    'UPDATE VALIDATION REFERENCE',
    'UPDATE VALIDATION ALIGNMENT',
    'UPDATE VALIDATION REBUILD',
    'UPDATE VALIDATION SKETCH',
    'UPDATE VALIDATION EXTRUDE',
    'UPDATE VALIDATION REVOLVE',
    'UPDATE VALIDATION SWEEP',
    'UPDATE VALIDATION LOFT',
    'UPDATE VALIDATION DATUM',
    'UPDATE VALIDATION SURFACE',
    'SET TOLERANCE',
    'SET WARNING THRESHOLD',
    'SET CRITICAL THRESHOLD',
    'SET COLOR SCALE',
    'SHOW COLOR SCALE',
    'SHOW DEVIATION BANDS',
    'SHOW POSITIVE DEVIATIONS',
    'SHOW NEGATIVE DEVIATIONS',
    'SHOW CONFIDENCE OVERLAY',
    'SHOW HEATMAP PREVIEW',
    'SHOW REGION DEVIATION',
    'SHOW REGION CONFIDENCE',
    'SHOW FEATURE INFLUENCE',
    'SHOW REFERENCE INFLUENCE',
    'SHOW REGION INFLUENCE',
    'SHOW ALIGNMENT INFLUENCE',
    'SHOW VALIDATION DEPENDENCIES',
    'SHOW VALIDATION IMPACT',
    'MARK VALIDATION DIRTY',
    'PERSIST VALIDATION',
    'SHOW VALIDATION WORKSPACE',
    'SHOW LIVE DASHBOARD',
    'SHOW DEVIATION INSPECTOR',
    'SHOW TOLERANCE MANAGER',
    'SHOW VALIDATION BASELINES',
    'SHOW KERNEL VALIDATION CAPABILITY',
  ])
    LiveValidationFelCommand(name, api),
];
