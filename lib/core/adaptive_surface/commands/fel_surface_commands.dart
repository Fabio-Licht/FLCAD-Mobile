import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../adapters/surface_source_adapters.dart';
import '../builders/surface_builder.dart';
import '../graph/surface_graph.dart';
import '../models/adaptive_surface.dart';
import '../models/surface_geometry.dart';

class CreateFELSurfaceCommand implements FELCommand {
  const CreateFELSurfaceCommand(this.name, this.kind);
  @override
  final String name;
  final SurfaceKind? kind;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final region = c.activeRegion, mesh = c.activeMesh;
    if (region == null || mesh == null) {
      throw StateError('SELECT REGION must run first');
    }
    final base = const SurfaceSourceAdapter().fromRegion(region, mesh),
        request = SurfaceBuildRequest(
          projectId: base.projectId,
          sourceIds: base.sourceIds,
          samples: base.samples,
          intent: 'general',
          targetKind: kind,
        ),
        surface = await c.surfaces.create(
          projectId: c.projectId,
          name: 'Surface ${DateTime.now().millisecondsSinceEpoch}',
          request: request,
          sourceKinds: {region.id: EngineeringNodeKind.region},
        );
    c.activeSurface = surface;
    return FELCommandResult(
      value: FELValue(FELType.surface, surface),
      description: '${surface.geometry.kind.name} surface created',
      undo: () => c.surfaces.delete(surface),
    );
  }
}

class ValidateFELSurfaceCommand implements FELCommand {
  const ValidateFELSurfaceCommand();
  @override
  String get name => 'VALIDATE SURFACE';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final s = c.activeSurface;
    if (s == null) throw StateError('No active surface');
    final valid = await c.surfaces.validate(s);
    return FELCommandResult(
      value: FELValue(FELType.boolean, valid),
      description: valid ? 'Surface valid' : 'Surface invalid',
    );
  }
}

class RefineFELSurfaceCommand implements FELCommand {
  const RefineFELSurfaceCommand(this.name, this.stage);
  @override
  final String name;
  final SurfaceStage stage;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final s = c.activeSurface;
    if (s == null) throw StateError('No active surface');
    final updated = await c.surfaces.refine(s, stage);
    c.activeSurface = updated;
    return FELCommandResult(
      value: FELValue(FELType.surface, updated),
      description: 'Surface ${stage.name}',
    );
  }
}

class RebuildFELSurfaceCommand implements FELCommand {
  const RebuildFELSurfaceCommand();
  @override
  String get name => 'REBUILD SURFACE';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final s = c.activeSurface, region = c.activeRegion, mesh = c.activeMesh;
    if (s == null || region == null || mesh == null) {
      throw StateError('Active surface and region required');
    }
    final request = const SurfaceSourceAdapter().fromRegion(
          region,
          mesh,
          intent: s.intent,
        ),
        updated = await c.surfaces.rebuild(s, request);
    c.activeSurface = updated;
    return FELCommandResult(
      value: FELValue(FELType.surface, updated),
      description: 'Surface rebuilt',
    );
  }
}

List<FELCommand> createSurfaceFELCommands() => const [
  CreateFELSurfaceCommand('CREATE SURFACE', null),
  CreateFELSurfaceCommand('FIT SURFACE', null),
  CreateFELSurfaceCommand('PATCH', SurfaceKind.patch),
  CreateFELSurfaceCommand('BLEND', SurfaceKind.blend),
  CreateFELSurfaceCommand('FILL', SurfaceKind.fill),
  CreateFELSurfaceCommand('SWEEP', SurfaceKind.sweep),
  CreateFELSurfaceCommand('LOFT', SurfaceKind.loft),
  CreateFELSurfaceCommand('OFFSET SURFACE', SurfaceKind.offset),
  ValidateFELSurfaceCommand(),
  RefineFELSurfaceCommand('OPTIMIZE SURFACE', SurfaceStage.optimized),
  RebuildFELSurfaceCommand(),
];
