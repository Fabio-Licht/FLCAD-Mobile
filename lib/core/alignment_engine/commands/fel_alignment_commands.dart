import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/alignment_api.dart';

class AlignmentFelCommand implements FELCommand {
  const AlignmentFelCommand(this.name, this.api);
  @override
  final String name;
  final AlignmentApi api;
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
      case 'PREVIEW ALIGNMENT':
        result = api.preview(id);
      case 'APPLY ALIGNMENT':
        api.apply(id);
      case 'ROLLBACK ALIGNMENT':
        api.rollback(id);
      case 'SHOW ALIGNMENTS':
        result = api.alignments;
      case 'SHOW ALIGNMENT QUALITY':
        result = api.quality(id);
      case 'SHOW ALIGNMENT HISTORY':
        result = api.engine.history.entries;
      case 'SHOW ALIGNMENT ANALYTICS':
        result = api.engine.analytics.toJson();
      case 'SHOW RMS':
        result = api.engine.alignments[id]?.rms;
      case 'SHOW TRANSFORMATION':
        result = api.engine.alignments[id]?.parameters.toJson();
      default:
        result = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createAlignmentFelCommands(AlignmentApi api) => [
  for (final name in const [
    'CREATE ALIGNMENT',
    'EDIT ALIGNMENT',
    'DELETE ALIGNMENT',
    'PREVIEW ALIGNMENT',
    'APPLY ALIGNMENT',
    'CANCEL ALIGNMENT',
    'COMMIT ALIGNMENT',
    'ROLLBACK ALIGNMENT',
    'REPLAY ALIGNMENT',
    'BEST FIT',
    'LOCAL BEST FIT',
    'REGION BEST FIT',
    'ICP ALIGNMENT',
    'PLANE ALIGNMENT',
    'AXIS ALIGNMENT',
    'POINT ALIGNMENT',
    'THREE POINT ALIGNMENT',
    'PLANE AXIS ALIGNMENT',
    'COORDINATE SYSTEM ALIGNMENT',
    'MESH TO MESH ALIGNMENT',
    'MESH TO CAD ALIGNMENT',
    'CAD TO CAD ALIGNMENT',
    'SEQUENTIAL ALIGNMENT',
    'HYBRID ALIGNMENT',
    'LOCK AXIS',
    'UNLOCK AXIS',
    'SHOW ALIGNMENTS',
    'SHOW ALIGNMENT',
    'SHOW ALIGNMENT QUALITY',
    'SHOW ALIGNMENT HISTORY',
    'SHOW ALIGNMENT ANALYTICS',
    'SHOW RMS',
    'SHOW MAXIMUM ERROR',
    'SHOW AVERAGE ERROR',
    'SHOW ALIGNMENT CONFIDENCE',
    'SHOW TRANSFORMATION',
    'SHOW TRANSFORMATION MATRIX',
    'SHOW ROTATION',
    'SHOW TRANSLATION',
    'SHOW DEGREES OF FREEDOM',
    'SHOW LOCKED AXES',
    'SHOW ALIGNMENT REFERENCES',
    'SHOW REFERENCE MAPPING',
    'SHOW ALIGNMENT DEPENDENCIES',
    'SHOW ALIGNMENT UPSTREAM',
    'SHOW ALIGNMENT DOWNSTREAM',
    'SHOW ALIGNMENT IMPACT',
    'SHOW ALIGNMENT WARNINGS',
    'SHOW ALIGNMENT READINESS',
    'SHOW ALIGNMENT STATUS',
    'SHOW ALIGNMENT ADVISOR',
    'SHOW EXPECTED ACCURACY',
    'SHOW EXPECTED REPEATABILITY',
    'SHOW ALIGNMENT STABILITY',
    'SHOW REFERENCE QUALITY',
    'SHOW TRANSFORMATION STABILITY',
    'SET ALIGNMENT TYPE',
    'SET ALIGNMENT TRANSLATION',
    'SET ALIGNMENT ROTATION',
    'SET ALIGNMENT MATRIX',
    'SET ALIGNMENT TOLERANCE',
    'SET ICP ITERATIONS',
    'ADD ALIGNMENT REFERENCE',
    'REMOVE ALIGNMENT REFERENCE',
    'MAP ALIGNMENT REFERENCE',
    'UNMAP ALIGNMENT REFERENCE',
    'MARK ALIGNMENT DIRTY',
    'REBUILD ALIGNMENT',
    'REBUILD ALIGNMENT PARTIAL',
    'SHOW ALIGNMENT FAILURES',
    'SHOW ALIGNMENT SUCCESS RATE',
    'SHOW ALIGNMENT WORKSPACE',
    'SHOW ALIGNMENT PREVIEW',
    'SHOW ALIGNMENT DIAGNOSTICS',
    'SHOW ALIGNMENT TIMELINE',
    'SHOW ALIGNMENT PRECISION',
    'SHOW BEST FIT COUNT',
    'SHOW ICP COUNT',
    'SHOW KERNEL ALIGNMENT CAPABILITY',
  ])
    AlignmentFelCommand(name, api),
];
