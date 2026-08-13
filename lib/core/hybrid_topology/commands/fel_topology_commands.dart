import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../utils/id_generator.dart';
import '../constraints/topology_constraint.dart';
import '../morphing/mesh_morph_engine.dart';
import '../workspace/local_workspace.dart';

class CreateLocalWorkspaceCommand implements FELCommand {
  const CreateLocalWorkspaceCommand();
  @override
  String get name => 'CREATE LOCAL WORKSPACE';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final object = c.activeHybridObject, region = c.activeRegion;
    if (object == null || region == null) {
      throw StateError('Active Hybrid Object and Region required');
    }
    final workspace = LocalWorkspace(
      id: IdGenerator.generate(),
      projectId: c.projectId,
      objectId: object.id,
      meshAssetId: region.meshId,
      selection: region.selection,
      sourceRegionIds: [region.id],
      createdAt: DateTime.now(),
    );
    c.topology.addWorkspace(workspace);
    c.activeWorkspace = workspace;
    return FELCommandResult(
      value: FELValue(FELType.selection, workspace),
      description:
          'Local workspace created (${workspace.referencedTriangleCount} referenced triangles)',
    );
  }
}

class MorphTopologyCommand implements FELCommand {
  const MorphTopologyCommand(this.name, this.operation);
  @override
  final String name;
  final MorphOperation operation;
  @override
  List<FELType> get argumentTypes => const [FELType.number];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final object = c.activeHybridObject,
        mesh = c.activeMesh,
        workspace = c.activeWorkspace;
    if (object == null || mesh == null || workspace == null) {
      throw StateError('Local workspace required');
    }
    final vertices = <int>{};
    for (final i in workspace.selection.indices) {
      final t = mesh.triangles[i];
      vertices.addAll([t.a, t.b, t.c]);
    }
    final amount = args.isEmpty ? .1 : (args.first.value as num).toDouble(),
        updated = await c.topology.morph(
          object,
          mesh,
          MorphRequest(
            operation: operation,
            vertexIndices: vertices,
            amount: amount,
          ),
        );
    c.activeHybridObject = updated;
    return FELCommandResult(
      value: FELValue(FELType.mesh, updated),
      description: '$name applied non-destructively',
    );
  }
}

class PreserveTopologyCommand implements FELCommand {
  const PreserveTopologyCommand();
  @override
  String get name => 'PRESERVE';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final w = c.activeWorkspace;
    if (w == null) throw StateError('Local workspace required');
    c.topology.addConstraint(
      c.projectId,
      TopologyConstraint(
        id: IdGenerator.generate(),
        type: TopologyConstraintType.frozen,
        vertexIndices: w.selection.indices,
      ),
    );
    return const FELCommandResult(
      value: FELValue.voidValue,
      description: 'Workspace preserved',
    );
  }
}

class UnsupportedTopologyCommand implements FELCommand {
  const UnsupportedTopologyCommand(this.name);
  @override
  final String name;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) => throw UnsupportedError('$name requires an installed topology adapter');
}

List<FELCommand> createTopologyFELCommands() => [
  const CreateLocalWorkspaceCommand(),
  const MorphTopologyCommand('MORPH', MorphOperation.push),
  const MorphTopologyCommand('RELAX', MorphOperation.relax),
  const MorphTopologyCommand('SMOOTH', MorphOperation.smooth),
  const MorphTopologyCommand('COMPENSATE', MorphOperation.compensation),
  const PreserveTopologyCommand(),
  for (final name in [
    'COPY REGION',
    'SMART COPY',
    'REPAIR TOPOLOGY',
    'REBUILD TOPOLOGY',
    'MERGE TOPOLOGY',
    'SPLIT TOPOLOGY',
    'VALIDATE TOPOLOGY',
  ])
    UnsupportedTopologyCommand(name),
];
