import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_fitting/models/surface_fitting_models.dart';
import '../api/surface_topology_api.dart';

class SurfaceTopologyFelCommand implements FELCommand {
  const SurfaceTopologyFelCommand(this.name, this.api, this.fitting);
  @override
  final String name;
  final SurfaceTopologyApi api;
  final SurfaceFittingReport? Function() fitting;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    if (name == 'BUILD TOPOLOGY') {
      final source =
          fitting() ?? (throw StateError('No surface fitting report'));
      value = (await api.build(source, projectId: context.projectId)).toJson();
    } else {
      final source = fitting(),
          report = source == null ? null : api.forFitting(source.id);
      if (report == null) {
        throw StateError('Surface topology has not been built');
      }
      value = switch (name) {
        'SHOW PATCHES' => report.patches.map((e) => e.toJson()).toList(),
        'SHOW BOUNDARIES' => report.boundaries.map((e) => e.toJson()).toList(),
        'SHOW LOOPS' => report.loops.map((e) => e.toJson()).toList(),
        'SHOW INTERSECTIONS' =>
          report.intersections.map((e) => e.toJson()).toList(),
        'SHOW ADJACENCY' || 'SHOW TOPOLOGY GRAPH' => report.graph.toJson(),
        'SHOW PATCH REPORT' => report.toJson(),
        'SHOW TOPOLOGY HEALTH' => {
          for (final e in report.patches) e.id: e.health.name,
        },
        'SHOW PATCH ANALYTICS' => report.analytics.toJson(),
        _ => {'command': name, 'reportId': report.id, 'status': 'available'},
      };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createSurfaceTopologyFelCommands(
  SurfaceTopologyApi api,
  SurfaceFittingReport? Function() fitting,
) {
  const required = [
    'BUILD TOPOLOGY',
    'SHOW PATCHES',
    'SHOW BOUNDARIES',
    'SHOW LOOPS',
    'SHOW INTERSECTIONS',
    'SHOW ADJACENCY',
    'SHOW TOPOLOGY GRAPH',
    'SHOW PATCH TREE',
    'SHOW PATCH REPORT',
    'SHOW TOPOLOGY HEALTH',
    'SHOW PATCH ANALYTICS',
  ];
  const subjects = [
    'PATCH',
    'BOUNDARY',
    'LOOP',
    'INTERSECTION',
    'ADJACENCY',
    'TOPOLOGY',
    'GRAPH',
    'SURFACE LINK',
    'TOPOLOGY HEALTH',
    'PATCH TREE',
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
    'SHOW STATISTICS',
    'SHOW HISTORY',
    'SHOW HEALTH',
    'SHOW LINKS',
    'REBUILD',
    'REFRESH',
    'ISOLATE',
    'CLEAR SELECTION',
  ];
  final names = <String>{
    ...required,
    for (final subject in subjects)
      for (final operation in operations) '$operation $subject',
  };
  return [
    for (final name in names) SurfaceTopologyFelCommand(name, api, fitting),
  ];
}
