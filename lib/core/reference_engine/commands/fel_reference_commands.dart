import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../models/reference_entity.dart';

class CreateReferenceCommand implements FELCommand {
  const CreateReferenceCommand(
    this.name,
    this.builderId,
    this.method,
    this.outputType,
  );
  @override
  final String name;
  final String builderId, method;
  final FELType outputType;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    final region = context.activeRegion;
    final sourceIds = <String>[];
    final parameters = <String, dynamic>{'method': method};
    if (region != null &&
        (method == 'region' || method == 'bestFit' || method == 'centroid')) {
      sourceIds.add(region.id);
    }
    if (method == 'normal') {
      final plane = context.pipelineValue.value;
      if (plane is! ReferenceEntity) {
        throw StateError('Plane reference required in pipeline');
      }
      sourceIds.add(plane.id);
    }
    if (builderId == 'coordinateSystem') {
      parameters.addAll({
        'origin': [0, 0, 0],
        'xAxis': [1, 0, 0],
        'yAxis': [0, 1, 0],
      });
    }
    if (sourceIds.isEmpty && builderId != 'coordinateSystem') {
      throw StateError('Reference source missing');
    }
    final reference = await context.references.create(
      projectId: context.projectId,
      name: '${name.toLowerCase()} ${DateTime.now().millisecondsSinceEpoch}',
      mode: ReferenceMode.live,
      recipe: ReferenceRecipe(builderId, parameters, sourceIds),
      meshes: context.meshes,
      regions: region == null ? const {} : {region.id: region},
    );
    context.loadedReferences[reference.id] = reference;
    return FELCommandResult(
      value: FELValue(outputType, reference),
      description: 'Reference created: ${reference.name}',
      undo: () => context.references.delete(reference),
    );
  }
}

class DeleteReferenceCommand implements FELCommand {
  @override
  String get name => 'DELETE REFERENCE';
  @override
  List<FELType> get argumentTypes => const [FELType.string];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    ReferenceEntity? reference;
    if (arguments.isNotEmpty) {
      final id = arguments.first.value as String;
      reference =
          context.loadedReferences[id] ??
          (await context.references.list(
            context.projectId,
          )).cast<ReferenceEntity?>().firstWhere(
            (r) => r!.id == id || r.name == id,
            orElse: () => null,
          );
    } else if (context.pipelineValue.value is ReferenceEntity) {
      reference = context.pipelineValue.value as ReferenceEntity;
    }
    if (reference == null) throw StateError('Reference not found');
    await context.references.delete(reference);
    final deleted = reference;
    return FELCommandResult(
      value: FELValue.voidValue,
      description: 'Reference deleted',
      undo: () => context.references.restore(deleted),
    );
  }
}

List<FELCommand> createReferenceFELCommands() => [
  const CreateReferenceCommand('FIT PLANE', 'plane', 'bestFit', FELType.plane),
  const CreateReferenceCommand(
    'CREATE PLANE',
    'plane',
    'region',
    FELType.plane,
  ),
  const CreateReferenceCommand('CREATE AXIS', 'axis', 'normal', FELType.axis),
  const CreateReferenceCommand(
    'CREATE POINT',
    'point',
    'centroid',
    FELType.point,
  ),
  const CreateReferenceCommand(
    'CREATE CURVE',
    'curve',
    'region',
    FELType.curve,
  ),
  const CreateReferenceCommand(
    'CREATE UCS',
    'coordinateSystem',
    'xyz',
    FELType.transformation,
  ),
  DeleteReferenceCommand(),
];
