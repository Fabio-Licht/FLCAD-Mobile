import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../api/surface_continuity_api.dart';

class SurfaceContinuityFelCommand implements FELCommand {
  const SurfaceContinuityFelCommand(this.name, this.api, this.topology);
  @override
  final String name;
  final SurfaceContinuityApi api;
  final SurfaceTopologyReport? Function() topology;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    if (name == 'RUN CONTINUITY') {
      final source =
          topology() ?? (throw StateError('No surface topology report'));
      value = (await api.run(source)).toJson();
    } else {
      final source = topology(),
          report = source == null ? null : api.forTopology(source.id);
      if (report == null) {
        throw StateError('Surface continuity has not been analyzed');
      }
      value = switch (name) {
        'SHOW G0' =>
          report.continuity
              .where((e) => e.level.name == 'g0')
              .map((e) => e.toJson())
              .toList(),
        'SHOW G1' =>
          report.continuity
              .where((e) => e.level.name == 'g1')
              .map((e) => e.toJson())
              .toList(),
        'SHOW G2' =>
          report.continuity
              .where((e) => e.level.name == 'g2')
              .map((e) => e.toJson())
              .toList(),
        'SHOW CURVATURE' || 'SHOW CURVATURE MAP' =>
          report.patchQualities.map((e) => e.curvature.toJson()).toList(),
        'SHOW ZEBRA' =>
          report.patchQualities.map((e) => e.zebra.toJson()).toList(),
        'SHOW REFLECTION' =>
          report.patchQualities.map((e) => e.reflection.toJson()).toList(),
        'SHOW DRAFT' || 'SHOW DRAFT MAP' =>
          report.patchQualities.map((e) => e.draft.toJson()).toList(),
        'SHOW QUALITY' || 'SHOW QUALITY REPORT' => report.toJson(),
        'SHOW SURFACE HEALTH' => {
          for (final e in report.patchQualities) e.patch.id: e.health.name,
        },
        'SHOW CONTINUITY GRAPH' => report.graph.toJson(),
        _ => {'command': name, 'reportId': report.id, 'status': 'available'},
      };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createSurfaceContinuityFelCommands(
  SurfaceContinuityApi api,
  SurfaceTopologyReport? Function() topology,
) {
  const required = [
    'RUN CONTINUITY',
    'SHOW G0',
    'SHOW G1',
    'SHOW G2',
    'SHOW CURVATURE',
    'SHOW GAUSSIAN',
    'SHOW ZEBRA',
    'SHOW REFLECTION',
    'SHOW DRAFT',
    'SHOW QUALITY',
    'SHOW SURFACE HEALTH',
    'SHOW CONTINUITY GRAPH',
    'SHOW QUALITY REPORT',
    'SHOW CURVATURE MAP',
    'SHOW DRAFT MAP',
  ];
  const subjects = [
    'CONTINUITY',
    'G0',
    'G1',
    'G2',
    'CURVATURE',
    'GAUSSIAN',
    'ZEBRA',
    'REFLECTION',
    'DRAFT',
    'QUALITY',
    'SURFACE HEALTH',
  ];
  const operations = [
    'LIST',
    'SELECT',
    'HIGHLIGHT',
    'INSPECT',
    'VALIDATE',
    'COMPARE',
    'EXPORT',
    'PERSIST',
    'SHOW MAP',
    'SHOW SCORE',
    'SHOW HISTORY',
    'SHOW STATISTICS',
    'CONFIGURE',
    'RESET',
    'REFRESH',
    'ISOLATE',
    'SHOW ADVISOR',
  ];
  final names = <String>{
    ...required,
    for (final s in subjects)
      for (final o in operations) '$o $s',
  };
  return [
    for (final name in names) SurfaceContinuityFelCommand(name, api, topology),
  ];
}
