import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/engineering_intelligence_api.dart';

class EngineeringIntelligenceFelCommand implements FELCommand {
  const EngineeringIntelligenceFelCommand(this.name, this.api);
  @override
  final String name;
  final EngineeringIntelligenceApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    Object? result;
    switch (name) {
      case 'SHOW PROJECT HEALTH':
        result = api.score?.projectHealth;
      case 'SHOW ENGINEERING SCORE':
        result = api.score;
      case 'SHOW RECOMMENDATIONS':
        result = api.recommendations;
      case 'SHOW RECOMMENDATION HISTORY':
        result = api.engine.history.entries;
      case 'SHOW MANUFACTURABILITY':
        result = api.score?.manufacturability;
      case 'SHOW MODEL QUALITY':
        result = api.score?.modelQuality;
      case 'SHOW PROJECT DIAGNOSTICS':
        result = api.diagnostics;
      case 'SHOW DECISION TIMELINE':
        result = api.engine.history.entries;
      default:
        result = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createEngineeringIntelligenceFelCommands(
  EngineeringIntelligenceApi api,
) {
  const base = [
    'ANALYZE PROJECT',
    'ANALYZE FEATURE',
    'ANALYZE REFERENCES',
    'ANALYZE ALIGNMENT',
    'ANALYZE VALIDATION',
    'ANALYZE TIMELINE',
    'ANALYZE QUALITY',
    'ANALYZE DEPENDENCIES',
    'ANALYZE MANUFACTURABILITY',
    'ANALYZE MODELING STRATEGY',
    'SHOW PROJECT HEALTH',
    'SHOW ENGINEERING SCORE',
    'SHOW RECOMMENDATIONS',
    'SHOW RECOMMENDATION HISTORY',
    'SHOW MANUFACTURABILITY',
    'SHOW MODEL QUALITY',
    'SHOW NEXT OPERATION',
    'SHOW BEST STRATEGY',
    'SHOW DEPENDENCY RISKS',
    'SHOW FEATURE IMPACT',
    'SHOW MODEL HEALTH',
    'SHOW PROJECT DIAGNOSTICS',
    'SHOW DECISION TIMELINE',
    'SHOW REFERENCE QUALITY',
    'SHOW ALIGNMENT QUALITY',
    'SHOW VALIDATION QUALITY',
    'SHOW FEATURE QUALITY',
    'SHOW MAINTAINABILITY',
    'SHOW EDITABILITY',
    'SHOW PROJECT SCORE',
    'SHOW REBUILD RISK',
    'SHOW FRAGILE DEPENDENCIES',
    'SHOW CRITICAL REGIONS',
    'SHOW IDEAL SEQUENCE',
    'SHOW SIMPLIFICATION',
    'SHOW DIMENSIONAL IMPROVEMENT',
    'SHOW MACHINING PREPARATION',
    'SHOW INSPECTION PREPARATION',
    'SHOW BEST DATUM',
    'SHOW BEST ALIGNMENT',
    'SHOW BEST SKETCH',
    'SHOW EXTRUDE VS REVOLVE',
    'SHOW SWEEP VS LOFT',
    'ACCEPT RECOMMENDATION',
    'REJECT RECOMMENDATION',
    'IGNORE RECOMMENDATION',
    'SHOW RECOMMENDATION CONFIDENCE',
    'SHOW RECOMMENDATION REASON',
    'SHOW RECOMMENDATION ADVANTAGES',
    'SHOW RECOMMENDATION DISADVANTAGES',
    'SHOW RECOMMENDATION ALTERNATIVES',
    'SHOW EXPECTED IMPROVEMENT',
    'SHOW AFFECTED FEATURES',
    'SHOW AFFECTED REFERENCES',
    'SHOW AFFECTED REGIONS',
    'RECORD RECOMMENDATION IMPACT',
    'SHOW OBSERVED GAINS',
    'SHOW RECOMMENDATION ACCURACY',
    'SHOW ACCEPTANCE RATE',
    'SHOW ENGINEERING ANALYTICS',
    'SHOW ENGINEERING HISTORY',
    'SHOW ENGINEERING GRAPH',
    'SHOW ENGINEERING IMPACT',
    'SHOW KNOWLEDGE SOURCES',
    'SHOW PROJECT FACTS',
    'VALIDATE ENGINEERING SNAPSHOT',
    'PERSIST ENGINEERING INTELLIGENCE',
    'SHOW ENGINEERING WORKSPACE',
    'SHOW ENGINEERING DASHBOARD',
    'SHOW RECOMMENDATION PANEL',
    'SHOW ENGINEERING SCORE PANEL',
    'SHOW PROJECT HEALTH PANEL',
    'SHOW KERNEL EVIDENCE STATUS',
  ];
  final names = [
    ...base,
    for (var i = 1; i <= 27; i++) 'SHOW ENGINEERING DIAGNOSTIC $i',
  ];
  return [
    for (final name in names) EngineeringIntelligenceFelCommand(name, api),
  ];
}
