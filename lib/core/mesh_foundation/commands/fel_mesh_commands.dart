import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/mesh_api.dart';

class MeshFelCommand implements FELCommand {
  const MeshFelCommand(this.name, this.api);
  @override
  final String name;
  final MeshApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    switch (name) {
      case 'OPEN STL':
      case 'IMPORT STL':
        if (args.isEmpty) throw ArgumentError('STL path is required');
        value = (await api.importStl(
          args.first.value.toString(),
          projectId: context.projectId,
        )).mesh.toJson();
      case 'SHOW MESH':
      case 'SHOW MESH INFO':
        value = api.engine.repository.meshes.values
            .map((e) => e.toJson())
            .toList();
      case 'SHOW MESH HEALTH':
        value = api.engine.repository.meshes.map(
          (k, v) => MapEntry(k, v.health.name),
        );
      case 'SHOW TRIANGLES':
        value = api.engine.analytics.triangles;
      case 'SHOW VERTICES':
        value = api.engine.analytics.vertices;
      case 'SHOW MESH DIAGNOSTICS':
        value = api.engine.diagnostics.map(
          (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
        );
      case 'SHOW IMPORT STATISTICS':
      case 'SHOW MESH ANALYTICS':
        value = api.engine.analytics.toJson();
      default:
        value = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createMeshFelCommands(MeshApi api) {
  const names = [
    'OPEN STL',
    'IMPORT STL',
    'RELOAD STL',
    'CLOSE MESH',
    'SHOW MESH',
    'SHOW MESH INFO',
    'SHOW MESH HEALTH',
    'SHOW TRIANGLES',
    'SHOW VERTICES',
    'SHOW BOUNDING BOX',
    'SHOW MESH DIAGNOSTICS',
    'SHOW IMPORT STATISTICS',
    'SHOW MESH ANALYTICS',
    'VERIFY STL',
    'SHOW MESH FILE',
    'SHOW MESH SIZE',
    'SHOW MESH CHECKSUM',
    'SHOW MESH UNITS',
    'SHOW MESH NORMALS',
    'SHOW MESH ORIENTATION',
    'SHOW MESH IMPORT DATE',
    'SHOW MESH KERNEL HANDLE',
    'SHOW MESH VALIDATION',
    'SHOW MESH STATE',
    'SHOW MESH METADATA',
    'SHOW MESH STATISTICS',
    'SHOW MESH MEMORY',
    'SHOW MESH SPEED',
    'SHOW MESH IMPORT TIME',
    'SHOW MESH KERNEL TIME',
    'SHOW MESH REPOSITORY TIME',
    'LIST MESHES',
    'FIND MESH',
    'REMOVE MESH',
    'RENAME MESH',
    'CLONE MESH METADATA',
    'REGISTER MESH',
    'PERSIST MESH',
    'PERSIST MESH METADATA',
    'PERSIST MESH STATISTICS',
    'PERSIST MESH DIAGNOSTICS',
    'PERSIST MESH HISTORY',
    'PERSIST MESH ANALYTICS',
    'PERSIST MESH VALIDATION',
    'VALIDATE STL',
    'VALIDATE MESH',
    'VALIDATE MESH FILE',
    'VALIDATE MESH CHECKSUM',
    'VALIDATE MESH BOUNDS',
    'VALIDATE MESH NORMALS',
    'VALIDATE MESH TRIANGLES',
    'VALIDATE MESH VERTICES',
    'VALIDATE MESH OVERFLOW',
    'VALIDATE MESH IMPORT',
    'SHOW INVALID TRIANGLES',
    'SHOW DEGENERATE TRIANGLES',
    'SHOW MISSING NORMALS',
    'SHOW PARTIAL IMPORT',
    'SHOW MESH WARNINGS',
    'SHOW MESH ERRORS',
    'SHOW MESH HISTORY',
    'SHOW LAST MESH IMPORT',
    'SHOW ACTIVE MESH',
    'SELECT MESH',
    'CLEAR MESH SELECTION',
    'SHOW MESH EXPLORER',
    'SHOW MESH STATISTICS PANEL',
    'SHOW MESH DIAGNOSTICS PANEL',
    'SHOW MESH HEALTH PANEL',
    'SHOW MESH VIEWPORT STATUS',
    'SHOW MESH WORKFLOW STATUS',
    'SHOW MESH SESSION STATUS',
    'SHOW MESH PROJECT STATUS',
    'SHOW MESH INTERACTIVE STATUS',
    'SHOW MESH RECOGNITION STATUS',
    'SHOW MESH VALIDATION STATUS',
    'SHOW STL FORMAT',
    'DETECT STL FORMAT',
    'VERIFY ASCII STL',
    'VERIFY BINARY STL',
    'IMPORT ASCII STL',
    'IMPORT BINARY STL',
    'IMPORT STL AUTO',
    'CANCEL STL IMPORT',
    'SHOW STL IMPORT PROGRESS',
    'SHOW STL READER',
    'SHOW OCCT MESH STATUS',
    'SHOW POLY TRIANGULATION',
    'SHOW MESH LIFETIME',
    'SHOW OPEN MESHES',
    'SHOW CLOSED MESHES',
    'CLOSE ALL MESHES',
    'RELOAD ALL MESHES',
    'COMPARE MESHES',
    'COMPARE MESH STATISTICS',
    'EXPORT MESH METADATA',
    'EXPORT MESH DIAGNOSTICS',
    'EXPORT MESH ANALYTICS',
    'SHOW MESH PROJECT FIRST',
    'SHOW MESH LAZY LOADING',
    'SHOW MESH BOOTSTRAP',
    'SHOW MESH CAPABILITIES',
    'SHOW MESH REPOSITORY',
  ];
  return [for (final name in names) MeshFelCommand(name, api)];
}
