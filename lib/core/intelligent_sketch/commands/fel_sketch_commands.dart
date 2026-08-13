import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../smart_regions/models/geometry.dart';
import '../builders/sketch_builder.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch.dart';
import '../models/sketch_context.dart';

class CreateSketchCommand implements FELCommand {
  const CreateSketchCommand();
  @override
  String get name => 'CREATE SKETCH';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final region = c.activeRegion;
    final context = region == null
        ? const SketchGeometryContext(
            id: 'world',
            kind: SketchContextKind.hybrid,
            sourceId: 'world',
            fingerprint: 'world',
          )
        : SketchGeometryContext(
            id: region.id,
            kind: SketchContextKind.region,
            sourceId: region.id,
            fingerprint: region.dna.hash,
          );
    final sketch = await c.sketches.create(
      projectId: c.projectId,
      name: 'Sketch ${DateTime.now().millisecondsSinceEpoch}',
      mode: SketchMode.live,
      contexts: [context],
    );
    c.activeSketch = sketch;
    c.loadedSketches[sketch.id] = sketch;
    return FELCommandResult(
      value: FELValue(FELType.sketch, sketch),
      description: 'Sketch created',
      undo: () => c.sketches.delete(sketch),
    );
  }
}

class CreateCenterCommand implements FELCommand {
  const CreateCenterCommand();
  @override
  String get name => 'CREATE CENTER';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final sketch = c.activeSketch;
    if (sketch == null) throw StateError('CREATE SKETCH must run first');
    final position = c.activeRegion?.statistics.centroid ?? const Vec3(0, 0, 0),
        entity = const DefaultSketchEntityBuilder().build(
          SketchEntityRecipe(SketchEntityKind.point, [
            SketchAnchor(
              position: position,
              contextId: sketch.contexts.first.id,
            ),
          ]),
        );
    final updated = await c.sketches.update(
      sketch,
      entities: [...sketch.entities, entity],
    );
    c.activeSketch = updated;
    return FELCommandResult(
      value: FELValue(FELType.point, entity),
      description: 'Center created',
      undo: () async {
        c.activeSketch = await c.sketches.update(
          updated,
          entities: sketch.entities,
        );
      },
    );
  }
}

class CreateCircleSketchCommand implements FELCommand {
  const CreateCircleSketchCommand();
  @override
  String get name => 'CREATE CIRCLE';
  @override
  List<FELType> get argumentTypes => const [FELType.number];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final sketch = c.activeSketch;
    if (sketch == null) throw StateError('CREATE SKETCH must run first');
    final center =
            sketch.entities
                .where((e) => e.kind == SketchEntityKind.point)
                .lastOrNull
                ?.anchors
                .first
                .position ??
            c.activeRegion?.statistics.centroid ??
            const Vec3(0, 0, 0),
        radius = (args.isEmpty ? 1 : (args.first.value as num)).toDouble(),
        entity = const DefaultSketchEntityBuilder().build(
          SketchEntityRecipe(
            SketchEntityKind.circle,
            [
              SketchAnchor(
                position: center,
                contextId: sketch.contexts.first.id,
              ),
            ],
            parameters: {'radius': radius},
          ),
        );
    final updated = await c.sketches.update(
      sketch,
      entities: [...sketch.entities, entity],
    );
    c.activeSketch = updated;
    return FELCommandResult(
      value: FELValue(FELType.curve, entity),
      description: 'Circle created',
      undo: () async {
        c.activeSketch = await c.sketches.update(
          updated,
          entities: sketch.entities,
        );
      },
    );
  }
}

class ApplySketchConstraintsCommand implements FELCommand {
  const ApplySketchConstraintsCommand();
  @override
  String get name => 'APPLY CONSTRAINTS';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final sketch = c.activeSketch;
    if (sketch == null) throw StateError('No active sketch');
    final solved = await c.sketches.solve(sketch);
    c.activeSketch = solved;
    return FELCommandResult(
      value: FELValue(FELType.sketch, solved),
      description:
          'Constraints solved (${solved.metadata['degreesOfFreedom']} DOF)',
    );
  }
}

class CreateProfileCommand implements FELCommand {
  const CreateProfileCommand();
  @override
  String get name => 'CREATE PROFILE';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final sketch = c.activeSketch;
    if (sketch == null) throw StateError('No active sketch');
    final updated = await c.sketches.update(
      sketch,
      intent: 'engineering-profile',
    );
    c.activeSketch = updated;
    return FELCommandResult(
      value: FELValue(FELType.sketch, updated),
      description: 'Engineering profile intent assigned',
    );
  }
}

class ProjectSurfaceCommand implements FELCommand {
  const ProjectSurfaceCommand();
  @override
  String get name => 'PROJECT SURFACE';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) =>
      throw UnsupportedError('PROJECT SURFACE requires a SurfaceSketchAdapter');
}

class DeleteSketchCommand implements FELCommand {
  const DeleteSketchCommand();
  @override
  String get name => 'DELETE SKETCH';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final sketch = c.activeSketch;
    if (sketch == null) throw StateError('No active sketch');
    await c.sketches.delete(sketch);
    c.activeSketch = null;
    return FELCommandResult(
      value: FELValue.voidValue,
      description: 'Sketch deleted',
      undo: () => c.sketches.restore(sketch),
    );
  }
}

List<FELCommand> createSketchFELCommands() => const [
  CreateSketchCommand(),
  CreateCenterCommand(),
  CreateCircleSketchCommand(),
  ApplySketchConstraintsCommand(),
  CreateProfileCommand(),
  ProjectSurfaceCommand(),
  DeleteSketchCommand(),
];
