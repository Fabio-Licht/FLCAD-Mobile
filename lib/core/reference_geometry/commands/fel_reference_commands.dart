import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/reference_api.dart';

class ReferenceFelCommand implements FELCommand {
  const ReferenceFelCommand(this.name, this.api);
  @override
  final String name;
  final ReferenceApi api;
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
      case 'SHOW REFERENCES':
        result = api.references;
      case 'SHOW DATUMS':
        result = api.references
            .where((e) => e.type.name.startsWith('datum'))
            .toList();
      case 'SHOW AXES':
        result = api.references
            .where((e) => e.type.name.toLowerCase().contains('axis'))
            .toList();
      case 'SHOW POINTS':
        result = api.references
            .where((e) => e.type.name.toLowerCase().contains('point'))
            .toList();
      case 'SHOW COORDINATE SYSTEMS':
        result = api.references
            .where((e) => e.type.name == 'coordinateSystem')
            .toList();
      case 'SHOW REFERENCE QUALITY':
        result = api.quality(id);
      case 'SHOW REFERENCE HISTORY':
        result = api.engine.history.entries;
      case 'SHOW REFERENCE ANALYTICS':
        result = api.engine.analytics.toJson();
      case 'VALIDATE REFERENCES':
        result = api.validate(id);
      case 'SUPPRESS DATUM':
        api.engine.suppress(id, true);
      case 'FREEZE DATUM':
        api.engine.freeze(id, true);
      default:
        result = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createReferenceFelCommands(ReferenceApi api) => [
  for (final name in const [
    'CREATE DATUM PLANE',
    'CREATE DATUM AXIS',
    'CREATE DATUM POINT',
    'CREATE COORDINATE SYSTEM',
    'CREATE CONSTRUCTION PLANE',
    'CREATE CONSTRUCTION AXIS',
    'CREATE CONSTRUCTION POINT',
    'CREATE REFERENCE CURVE',
    'CREATE REFERENCE FRAME',
    'CREATE REFERENCE GROUP',
    'EDIT DATUM',
    'DELETE DATUM',
    'RENAME DATUM',
    'MOVE DATUM',
    'SHOW REFERENCES',
    'SHOW DATUMS',
    'SHOW AXES',
    'SHOW POINTS',
    'SHOW COORDINATE SYSTEMS',
    'VALIDATE REFERENCES',
    'SHOW REFERENCE QUALITY',
    'SHOW REFERENCE HISTORY',
    'SHOW REFERENCE ANALYTICS',
    'SUPPRESS DATUM',
    'UNSUPPRESS DATUM',
    'FREEZE DATUM',
    'UNFREEZE DATUM',
    'GROUP DATUM',
    'UNGROUP DATUM',
    'SHOW DATUM',
    'SHOW REFERENCE PARAMETERS',
    'SHOW REFERENCE PREVIEW',
    'PREVIEW DATUM',
    'CONFIRM DATUM',
    'REBUILD DATUM',
    'ROLLBACK DATUM',
    'SET REFERENCE VISIBILITY',
    'SHOW REFERENCE VISIBILITY',
    'SHOW REFERENCE DEPENDENCIES',
    'SHOW REFERENCE PARENTS',
    'SHOW REFERENCE CHILDREN',
    'SHOW REFERENCE IMPACT',
    'SHOW REFERENCE WARNINGS',
    'SHOW REFERENCE READINESS',
    'SHOW REFERENCE FAILURES',
    'SHOW REFERENCE SUCCESS RATE',
    'SHOW REFERENCE ADVISOR',
    'SHOW ALIGNMENT READINESS',
    'SHOW PLANE QUALITY',
    'SHOW AXIS QUALITY',
    'SHOW DEPENDENCY QUALITY',
    'CREATE OFFSET PLANE',
    'CREATE THREE POINT PLANE',
    'CREATE MID PLANE',
    'CREATE FACE PLANE',
    'CREATE TWO POINT AXIS',
    'CREATE EDGE AXIS',
    'CREATE VECTOR AXIS',
    'CREATE XYZ POINT',
    'CREATE MESH PICK POINT',
    'CREATE EDGE MIDPOINT',
    'CREATE ORIGIN SYSTEM',
    'CREATE XYZ SYSTEM',
    'CREATE PLANE AXIS SYSTEM',
    'CREATE IMPORTED SYSTEM',
    'SHOW REFERENCE WORKSPACE',
    'SHOW CONSTRUCTION GEOMETRY',
    'SHOW REFERENCE GROUPS',
    'MARK REFERENCE DIRTY',
    'REBUILD REFERENCES PARTIAL',
    'SHOW KERNEL REFERENCE CAPABILITY',
  ])
    ReferenceFelCommand(name, api),
];
