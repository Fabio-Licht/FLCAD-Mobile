import '../../smart_regions/engine/smart_border_engine.dart';
import '../../smart_regions/models/smart_region.dart';
import '../../smart_regions/selection/triangle_selection.dart';
import '../runtime/fel_context.dart';
import '../types/fel_type.dart';
import 'fel_command.dart';
import '../../reference_engine/commands/fel_reference_commands.dart';
import '../../intelligent_sketch/commands/fel_sketch_commands.dart';
import '../../adaptive_surface/commands/fel_surface_commands.dart';
import '../../hybrid_topology/commands/fel_topology_commands.dart';
import '../../parametric_engineering/commands/fel_parametric_commands.dart';
import 'fel_geometry_commands.dart';
import '../../reverse_intelligence/commands/fel_reverse_intelligence_commands.dart';
import '../../engineering_knowledge/commands/fel_knowledge_commands.dart';
import '../../engineering_cognition/commands/fel_cognition_commands.dart';
import '../../autonomous_reconstruction/commands/fel_autonomous_commands.dart';
import '../../engineering_decision/commands/fel_decision_commands.dart';
import '../../geometric_recognition/commands/fel_recognition_commands.dart';
import '../../professional_recognition/commands/fel_professional_recognition_commands.dart';
import '../../engineering_reconstruction/commands/fel_reconstruction_intelligence_commands.dart';
import '../../cad_kernel/commands/fel_kernel_commands.dart';
import '../../cad_builder/commands/fel_cad_builder_commands.dart';
import '../../cad_features/commands/fel_feature_commands.dart';
import '../../surface_intelligence/commands/fel_surface_intelligence_commands.dart';
import '../../surface_generation/commands/fel_surface_generation_commands.dart';
import '../../hybrid_surface_engine/commands/fel_hybrid_surface_commands.dart';

class SelectRegionCommand implements FELCommand {
  @override
  String get name => 'SELECT REGION';
  @override
  List<FELType> get argumentTypes => const [FELType.string];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final name = args.first.value as String;
    final all = await context.regions.repository.loadRegions(context.projectId);
    final region = all.cast<SmartRegion?>().firstWhere(
      (r) => r!.name.toUpperCase() == name.toUpperCase() || r.id == name,
      orElse: () => null,
    );
    if (region == null) throw StateError('Região inexistente: $name');
    context.activeRegion = region;
    context.activeSelection = region.selection;
    context.activeMesh = context.meshes[region.meshId];
    return FELCommandResult(
      value: FELValue(FELType.region, region),
      description: 'Região selecionada: ${region.name}',
    );
  }
}

abstract class BorderCommand implements FELCommand {
  const BorderCommand(this.name);
  @override
  final String name;
  @override
  List<FELType> get argumentTypes => const [FELType.number];
  TriangleSelection apply(
    SmartBorderEngine engine,
    dynamic mesh,
    TriangleSelection input,
    int rings,
  );
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final region = context.activeRegion,
        mesh = context.activeMesh,
        input = context.activeSelection;
    if (region == null || mesh == null || input == null) {
      throw StateError('SELECT REGION deve ser executado antes');
    }
    final rings = ((args.isEmpty ? 1 : args.first.value) as num).round().clamp(
      1,
      100,
    );
    final output = apply(const SmartBorderEngine(), mesh, input, rings);
    final previous = input;
    context.activeSelection = output;
    return FELCommandResult(
      value: FELValue(FELType.selection, output),
      description: '$name $rings',
      undo: () async => context.activeSelection = previous,
    );
  }
}

class ExpandRegionCommand extends BorderCommand {
  const ExpandRegionCommand() : super('EXPAND REGION');
  @override
  TriangleSelection apply(
    SmartBorderEngine e,
    dynamic m,
    TriangleSelection i,
    int r,
  ) => e.expand(m, i, rings: r);
}

class ShrinkRegionCommand extends BorderCommand {
  const ShrinkRegionCommand() : super('SHRINK REGION');
  @override
  TriangleSelection apply(
    SmartBorderEngine e,
    dynamic m,
    TriangleSelection i,
    int r,
  ) => e.shrink(m, i, rings: r);
}

class SmoothRegionCommand extends BorderCommand {
  const SmoothRegionCommand() : super('SMOOTH REGION');
  @override
  TriangleSelection apply(
    SmartBorderEngine e,
    dynamic m,
    TriangleSelection i,
    int r,
  ) => e.smooth(m, i, iterations: r);
}

class SaveProjectCommand implements FELCommand {
  @override
  String get name => 'SAVE PROJECT';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final region = context.activeRegion,
        selection = context.activeSelection,
        mesh = context.activeMesh;
    if (region != null &&
        selection != null &&
        mesh != null &&
        selection.indices != region.selection.indices) {
      context.activeRegion = await context.regions.updateSelection(
        region,
        mesh,
        selection,
        'FEL SAVE PROJECT',
      );
    }
    return const FELCommandResult(
      value: FELValue.voidValue,
      description: 'Projeto salvo',
    );
  }
}

class UnsupportedEngineeringCommand implements FELCommand {
  const UnsupportedEngineeringCommand(this.name, this.argumentTypes);
  @override
  final String name;
  @override
  final List<FELType> argumentTypes;
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) => throw UnsupportedError(
    '$name está tipado, mas o adapter de engenharia ainda não está instalado',
  );
}

FELCommandRegistry createNativeCommandRegistry() {
  final r = FELCommandRegistry()
    ..register(SelectRegionCommand())
    ..register(const ExpandRegionCommand())
    ..register(const ShrinkRegionCommand())
    ..register(const SmoothRegionCommand())
    ..register(SaveProjectCommand());
  for (final name in [
    'CREATE CYLINDER',
    'CREATE CONE',
    'CREATE SPHERE',
    'CREATE SOLID',
    'DELETE',
    'COPY',
    'MOVE',
    'ROTATE',
    'SCALE',
    'FIT CYLINDER',
    'FIT SPHERE',
    'EXPORT STL',
    'EXPORT STEP',
    'EXPORT IGES',
  ]) {
    r.register(UnsupportedEngineeringCommand(name, const []));
  }
  for (final command in createReferenceFELCommands()) {
    r.register(command);
  }
  for (final command in createSketchFELCommands()) {
    r.register(command);
  }
  for (final command in createSurfaceFELCommands()) {
    r.register(command);
  }
  for (final command in createTopologyFELCommands()) {
    r.register(command);
  }
  for (final command in createParametricFELCommands()) {
    r.register(command);
  }
  for (final command in createGeometryFELCommands()) {
    r.register(command);
  }
  for (final command in createReverseIntelligenceFELCommands()) {
    r.register(command);
  }
  for (final command in createKnowledgeFELCommands()) {
    r.register(command);
  }
  for (final command in createCognitionFELCommands()) {
    r.register(command);
  }
  for (final command in createAutonomousFELCommands()) {
    r.register(command);
  }
  for (final command in createDecisionFELCommands()) {
    r.register(command);
  }
  for (final command in createRecognitionFELCommands()) {
    r.register(command);
  }
  for (final command in createProfessionalRecognitionFELCommands()) {
    r.register(command);
  }
  for (final command in createERIFELCommands()) {
    r.register(command);
  }
  for (final command in createKernelFELCommands()) {
    r.register(command);
  }
  for (final command in createCadBuilderFELCommands()) {
    r.register(command);
  }
  for (final command in createFeatureFELCommands()) {
    r.register(command);
  }
  for (final command in createSurfaceIntelligenceFELCommands()) {
    r.register(command);
  }
  for (final command in createSurfaceGenerationFELCommands()) {
    r.register(command);
  }
  for (final command in createHybridSurfaceFELCommands()) {
    r.register(command);
  }
  for (final name in [
    'INTERSECTION',
    'TRANSFORM',
    'TRANSLATE',
    'FIT LINE',
    'FIT CIRCLE',
  ]) {
    if (r.find(name) == null) {
      r.register(UnsupportedEngineeringCommand(name, const []));
    }
  }
  return r;
}
