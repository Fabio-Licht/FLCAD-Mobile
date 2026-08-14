import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_morph/models/surface_morph_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../api/surface_extend_api.dart';
import '../models/surface_extend_models.dart';

class SurfaceExtendFelCommand implements FELCommand {
  const SurfaceExtendFelCommand(
    this.name,
    this.api,
    this.topology,
    this.quality,
  );
  @override
  final String name;
  final SurfaceExtendApi api;
  final SurfaceTopologyReport? Function() topology;
  final SurfaceQualityReport? Function() quality;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    final t = topology(), q = quality();
    if (name == 'BEGIN EXTEND') {
      if (t == null || t.patches.isEmpty) throw StateError('No topology');
      final p = t.patches.first;
      value = api
          .begin(
            type: ExtendType.distance,
            patch: p,
            boundaryId: p.boundaryIds.first,
            anchors: [
              MorphAnchor(
                id: 'fel',
                type: AnchorType.boundary,
                targetId: p.boundaryIds.first,
                position: const [0, 0, 0],
              ),
            ],
            parameters: const {'distance': 1},
          )
          .toJson();
    } else if (name == 'SHOW EXTEND ANALYSIS') {
      value = api.sessions.lastOrNull?.analysis?.toJson();
    } else {
      value = {
        'command': name,
        'status': 'available',
        'automaticExecution': false,
        'hasContext': t != null && q != null,
      };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createSurfaceExtendFelCommands(
  SurfaceExtendApi api,
  SurfaceTopologyReport? Function() topology,
  SurfaceQualityReport? Function() quality,
) {
  const required = [
    'BEGIN EXTEND',
    'EXTEND DISTANCE',
    'EXTEND ANGLE',
    'EXTEND VECTOR',
    'EXTEND UNTIL',
    'EXTEND G1',
    'EXTEND G2',
    'EXTEND DRAFT',
    'EXTEND MANUFACTURING',
    'SMART EXTEND',
    'SHOW EXTEND ANALYSIS',
  ];
  const subjects = [
    'DISTANCE EXTEND',
    'ANGLE EXTEND',
    'VECTOR EXTEND',
    'UNTIL SURFACE',
    'UNTIL PLANE',
    'UNTIL CURVE',
    'TANGENT EXTEND',
    'CURVATURE EXTEND',
    'MANUFACTURING EXTEND',
    'DRAFT EXTEND',
    'SMART EXTEND',
    'EXTEND ANALYZER',
    'EXTEND ANCHORS',
    'EXTEND PREVIEW',
    'EXTEND VALIDATION',
    'EXTEND QUALITY',
    'EXTEND REFLECTION',
    'EXTEND ZEBRA',
    'EXTEND TWIST',
    'EXTEND HISTORY',
    'EXTEND ANALYTICS',
    'TOOLING INTENT',
  ];
  const actions = [
    'SHOW',
    'BEGIN',
    'PREVIEW',
    'VALIDATE',
    'COMMIT',
    'ROLLBACK',
    'CANCEL',
    'LIST',
    'SELECT',
    'HIGHLIGHT',
    'INSPECT',
    'CONFIGURE',
    'RESET',
    'PERSIST',
    'EXPORT',
    'SHOW STATUS',
  ];
  final names = <String>{
    ...required,
    for (final s in subjects)
      for (final a in actions) '$a $s',
  };
  return [
    for (final n in names) SurfaceExtendFelCommand(n, api, topology, quality),
  ];
}
