import 'dart:io';

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
import '../../sketch_engine/commands/fel_sketch_engine_commands.dart';
import '../../sketch_engine/integration/sketch_factory.dart';
import '../../sketch_constraints/commands/fel_constraint_commands.dart';
import '../../sketch_constraints/integration/constraint_factory.dart';
import '../../sketch_editor/commands/fel_editor_commands.dart';
import '../../sketch_editor/integration/editor_factory.dart';
import '../../profile_recognition/commands/fel_profile_commands.dart';
import '../../profile_recognition/integration/profile_factory.dart';
import '../../feature_modeling/commands/fel_feature_modeling_commands.dart';
import '../../feature_modeling/integration/feature_modeling_factory.dart';
import '../../extrude_feature/commands/fel_extrude_commands.dart';
import '../../extrude_feature/integration/extrude_factory.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../revolve_feature/commands/fel_revolve_commands.dart';
import '../../revolve_feature/integration/revolve_factory.dart';
import '../../transition_features/commands/fel_transition_commands.dart';
import '../../transition_features/integration/transition_factory.dart';
import '../../reference_geometry/commands/fel_reference_commands.dart';
import '../../reference_geometry/integration/reference_factory.dart';
import '../../alignment_engine/commands/fel_alignment_commands.dart';
import '../../alignment_engine/integration/alignment_factory.dart';
import '../../live_validation/commands/fel_validation_commands.dart';
import '../../live_validation/integration/validation_factory.dart';
import '../../engineering_intelligence/commands/fel_intelligence_commands.dart';
import '../../engineering_intelligence/integration/intelligence_factory.dart';

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
  final sketchEngineApi = const SketchEngineFactory().create(Directory.current);
  for (final command in createSketchEngineFelCommands(sketchEngineApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final constraintApi = const ConstraintFactory().create(
    projectDirectory: Directory.current,
    sketch: sketchEngineApi,
  );
  for (final command in createConstraintFelCommands(constraintApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final editorApi = const SketchEditorFactory().create(
    projectDirectory: Directory.current,
    sketch: sketchEngineApi,
    constraints: constraintApi,
  );
  for (final command in createSketchEditorFelCommands(editorApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final profileApi = const ProfileRecognitionFactory().create(
    projectDirectory: Directory.current,
    sketch: sketchEngineApi,
  );
  for (final command in createProfileFelCommands(profileApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final featureModelingApi = const FeatureModelingFactory().create(
    projectDirectory: Directory.current,
    projectId: 'local',
  );
  for (final command in createFeatureModelingFelCommands(featureModelingApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final extrudeApi = const ExtrudeFactory().create(
    projectDirectory: Directory.current,
    projectId: 'local',
    kernel: const UnavailableGeometryKernel(),
    profiles: profileApi,
    featurePlatform: featureModelingApi,
  );
  for (final command in createExtrudeFelCommands(extrudeApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final revolveApi = const RevolveFactory().create(
    projectDirectory: Directory.current,
    projectId: 'local',
    kernel: const UnavailableGeometryKernel(),
    profiles: profileApi,
    featurePlatform: featureModelingApi,
    extrudes: extrudeApi,
  );
  for (final command in createRevolveFelCommands(revolveApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final transitionApi = const TransitionFactory().create(
    projectDirectory: Directory.current,
    projectId: 'local',
    kernel: const UnavailableGeometryKernel(),
    profiles: profileApi,
    featurePlatform: featureModelingApi,
    extrudes: extrudeApi,
    revolves: revolveApi,
  );
  for (final command in createTransitionFelCommands(transitionApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final referenceApi = const ReferenceFactory().create(
    projectDirectory: Directory.current,
    projectId: 'local',
    kernel: const UnavailableGeometryKernel(),
    sketch: sketchEngineApi,
    profiles: profileApi,
    features: featureModelingApi,
    transitions: transitionApi,
  );
  for (final command in createReferenceFelCommands(referenceApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final alignmentApi = const AlignmentFactory().create(
    projectDirectory: Directory.current,
    projectId: 'local',
    kernel: const UnavailableGeometryKernel(),
    references: referenceApi,
    features: featureModelingApi,
    transitions: transitionApi,
  );
  for (final command in createAlignmentFelCommands(alignmentApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final validationApi = const LiveValidationFactory().create(
    projectDirectory: Directory.current,
    kernel: const UnavailableGeometryKernel(),
    references: referenceApi,
    alignments: alignmentApi,
    sketches: sketchEngineApi,
    features: featureModelingApi,
    transitions: transitionApi,
  );
  for (final command in createLiveValidationFelCommands(validationApi)) {
    if (r.find(command.name) == null) r.register(command);
  }
  final intelligenceApi = const EngineeringIntelligenceFactory().create(
    projectDirectory: Directory.current,
    kernel: const UnavailableGeometryKernel(),
    references: referenceApi,
    alignments: alignmentApi,
    validation: validationApi,
    sketches: sketchEngineApi,
    features: featureModelingApi,
  );
  for (final command in createEngineeringIntelligenceFelCommands(
    intelligenceApi,
  )) {
    if (r.find(command.name) == null) r.register(command);
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
