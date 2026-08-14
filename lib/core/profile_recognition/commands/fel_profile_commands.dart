import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/profile_recognition_api.dart';

class ProfileFelCommand implements FELCommand {
  const ProfileFelCommand(this.name, this.api);
  @override
  final String name;
  final ProfileRecognitionApi api;
  @override
  List<FELType> get argumentTypes => const [];
  String _text(List<FELValue> a, int i) =>
      a.length > i ? a[i].value.toString() : '';
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> a,
  ) async {
    Object? result;
    switch (name) {
      case 'RECOGNIZE PROFILES':
        api.recognize();
        result = api.profiles;
      case 'SHOW REGIONS':
      case 'LIST REGIONS':
        result = api.regions;
      case 'SHOW LOOPS':
      case 'LIST LOOPS':
        result = api.loops;
      case 'LIST PROFILES':
        result = api.profiles;
      case 'SHOW TOPOLOGY':
        result = api.engine.graphs.topology;
      case 'SHOW INTENT':
        result = api.intent;
      case 'SHOW QUALITY':
        result = api.quality;
      case 'SHOW FEATURE READINESS':
        result = api.readiness;
      case 'SHOW PROFILE GRAPH':
        result = api.engine.graphs.profiles;
      case 'SHOW REGION GRAPH':
        result = api.engine.graphs.regions;
      case 'SHOW LOOP GRAPH':
        result = api.engine.graphs.loops;
      case 'VALIDATE PROFILE':
      case 'VALIDATE REGION':
        result = api.validation;
      case 'MERGE REGION':
        result = api.engine.merge(_text(a, 0), _text(a, 1));
      case 'SPLIT REGION':
        result = api.engine.split(_text(a, 0));
      case 'SHOW ADVISOR':
        result = api.recommendations();
      case 'SHOW MANUFACTURABILITY':
        result = api.quality?.manufacturability;
      default:
        result = {
          'command': name,
          'status': 'available',
          'automaticAction': false,
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createProfileFelCommands(ProfileRecognitionApi api) => [
  for (final n in const [
    'RECOGNIZE PROFILES',
    'SHOW REGIONS',
    'SHOW LOOPS',
    'SHOW TOPOLOGY',
    'SHOW INTENT',
    'SHOW QUALITY',
    'SHOW FEATURE READINESS',
    'SHOW PROFILE GRAPH',
    'SHOW REGION GRAPH',
    'SHOW LOOP GRAPH',
    'VALIDATE PROFILE',
    'VALIDATE REGION',
    'LIST PROFILES',
    'LIST REGIONS',
    'LIST LOOPS',
    'MERGE REGION',
    'SPLIT REGION',
    'SHOW ADVISOR',
    'SHOW MANUFACTURABILITY',
    'SHOW PROFILE QUALITY',
    'SHOW REGION QUALITY',
    'SHOW LOOP QUALITY',
    'SHOW TOPOLOGY QUALITY',
    'SHOW ISLANDS',
    'SHOW HOLES',
    'SHOW OPEN PROFILES',
    'SHOW CLOSED PROFILES',
    'SHOW INVALID PROFILES',
    'SHOW TINY GAPS',
    'SHOW CROSSINGS',
    'SHOW DUPLICATES',
    'SHOW CONTAINMENT GRAPH',
    'SHOW ADJACENCY GRAPH',
    'SHOW INTENT CONFIDENCE',
    'PREPARE FEATURES',
  ])
    ProfileFelCommand(n, api),
];
