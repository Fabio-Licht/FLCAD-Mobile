import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../api/surface_morph_api.dart';
import '../models/surface_morph_models.dart';

class SurfaceMorphFelCommand implements FELCommand {
  const SurfaceMorphFelCommand(
    this.name,
    this.api,
    this.topology,
    this.quality,
  );
  @override
  final String name;
  final SurfaceMorphApi api;
  final SurfaceTopologyReport? Function() topology;
  final SurfaceQualityReport? Function() quality;
  @override
  List<FELType> get argumentTypes => const [];
  MorphSession get _latest =>
      api.sessions.lastOrNull ?? (throw StateError('No morph session'));
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? result;
    final t = topology(), q = quality();
    switch (name) {
      case 'BEGIN SURFACE MORPH':
        if (t == null || t.patches.isEmpty) {
          throw StateError('No surface topology');
        }
        result = api
            .begin(
              tool: MorphTool.move,
              patch: t.patches.first,
              anchors: [
                MorphAnchor(
                  id: 'fel-anchor',
                  type: AnchorType.fixed,
                  targetId: t.patches.first.id,
                  position: const [0, 0, 0],
                ),
              ],
              radius: 1,
              falloff: FalloffType.smooth,
            )
            .toJson();
      case 'PREVIEW SURFACE MORPH':
        if (t == null || q == null) {
          throw StateError('Morph context is incomplete');
        }
        result = api.preview(_latest.id, t, q).toJson();
      case 'VALIDATE SURFACE MORPH':
        if (t == null || q == null) {
          throw StateError('Morph context is incomplete');
        }
        result = api.validate(_latest.id, t, q).toJson();
      case 'COMMIT SURFACE MORPH':
        if (t == null || q == null) {
          throw StateError('Morph context is incomplete');
        }
        result = (await api.commit(
          _latest.id,
          topology: t,
          quality: q,
          projectId: 'fel-project',
        )).toJson();
      case 'ROLLBACK SURFACE MORPH':
        result = (await api.rollback(_latest.id)).toJson();
      case 'CANCEL SURFACE MORPH':
        result = api.cancel(_latest.id).toJson();
      case 'SHOW MORPH SESSIONS':
        result = api.sessions.map((e) => e.toJson()).toList();
      case 'SHOW MORPH PREVIEW':
        result = _latest.preview?.toJson();
      case 'SHOW MORPH VALIDATION':
        result = _latest.validation?.toJson();
      case 'SHOW MORPH ANALYTICS':
        result = api.engine.analytics.toJson();
      default:
        result = {
          'command': name,
          'status': 'available',
          'automaticExecution': false,
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createSurfaceMorphFelCommands(
  SurfaceMorphApi api,
  SurfaceTopologyReport? Function() topology,
  SurfaceQualityReport? Function() quality,
) {
  const required = [
    'BEGIN SURFACE MORPH',
    'PREVIEW SURFACE MORPH',
    'VALIDATE SURFACE MORPH',
    'COMMIT SURFACE MORPH',
    'ROLLBACK SURFACE MORPH',
    'CANCEL SURFACE MORPH',
    'SHOW MORPH SESSIONS',
    'SHOW MORPH PREVIEW',
    'SHOW MORPH VALIDATION',
    'SHOW MORPH ANALYTICS',
  ];
  const subjects = [
    'MORPH TREE',
    'FIXED ANCHOR',
    'SOFT ANCHOR',
    'BOUNDARY ANCHOR',
    'SURFACE ANCHOR',
    'CURVE ANCHOR',
    'POINT ANCHOR',
    'MULTI ANCHOR',
    'INFLUENCE REGION',
    'SOFT SELECTION',
    'LINEAR FALLOFF',
    'SMOOTH FALLOFF',
    'GAUSSIAN FALLOFF',
    'BELL FALLOFF',
    'CUSTOM CURVE',
    'MANUFACTURING INTENT',
    'CONSTRAINT GROUP',
    'MORPH ADVISOR',
    'MORPH HISTORY',
  ];
  const actions = [
    'SHOW',
    'LIST',
    'ADD',
    'REMOVE',
    'SELECT',
    'HIGHLIGHT',
    'INSPECT',
    'CONFIGURE',
    'PREVIEW',
    'VALIDATE',
    'RESET',
    'PERSIST',
    'EXPORT',
    'ENABLE',
    'DISABLE',
    'SHOW STATUS',
  ];
  final names = <String>{
    ...required,
    for (final subject in subjects)
      for (final action in actions) '$action $subject',
  };
  return [
    for (final name in names)
      SurfaceMorphFelCommand(name, api, topology, quality),
  ];
}
