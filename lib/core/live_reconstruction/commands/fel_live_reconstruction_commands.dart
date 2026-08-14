import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../api/live_reconstruction_api.dart';
import '../models/live_reconstruction_models.dart';

class LiveReconstructionFelCommand implements FELCommand {
  const LiveReconstructionFelCommand(
    this.name,
    this.api,
    this.operation,
    this.topology,
    this.quality,
  );
  @override
  final String name;
  final LiveReconstructionApi api;
  final SurfaceOperation? Function() operation;
  final SurfaceTopologyReport? Function() topology;
  final SurfaceQualityReport? Function() quality;
  @override
  List<FELType> get argumentTypes => const [];
  LiveReconstruction get _latest =>
      api.reconstructions.lastOrNull ??
      (throw StateError('No live reconstruction'));
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? result;
    switch (name) {
      case 'BEGIN LIVE RECONSTRUCTION':
        final op = operation(), top = topology(), q = quality();
        if (op == null || top == null || q == null) {
          throw StateError('Live reconstruction context is incomplete');
        }
        result = api.begin(op, top, q).toJson();
      case 'PREVIEW LIVE UPDATE':
        final q = quality() ?? (throw StateError('No surface quality report'));
        result = api.preview(_latest.id, q).toJson();
      case 'VALIDATE LIVE UPDATE':
        result = api.validate(_latest.id).toJson();
      case 'RUN INCREMENTAL UPDATE':
        result = api.update(_latest.id).toJson();
      case 'ROLLBACK LIVE UPDATE':
        result = (await api.rollback(_latest.id)).toJson();
      case 'COMMIT LIVE UPDATE':
        final q = quality() ?? (throw StateError('No surface quality report'));
        result = (await api.commit(
          _latest.id,
          projectId: 'fel-project',
          quality: q,
        )).toJson();
      case 'SHOW DEPENDENCY GRAPH':
        result = _latest.graph.toJson();
      case 'SHOW AFFECTED OBJECTS':
        result = _latest.preview?.affected.toJson();
      case 'SHOW RECONSTRUCTION ANALYTICS':
        result = api.engine.analytics.toJson();
      case 'SHOW RECONSTRUCTION TIMELINE':
        result = _latest.timeline;
      default:
        result = {
          'command': name,
          'status': 'available',
          'incremental': true,
          'automaticExecution': false,
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createLiveReconstructionFelCommands(
  LiveReconstructionApi api,
  SurfaceOperation? Function() operation,
  SurfaceTopologyReport? Function() topology,
  SurfaceQualityReport? Function() quality,
) {
  const required = [
    'BEGIN LIVE RECONSTRUCTION',
    'PREVIEW LIVE UPDATE',
    'VALIDATE LIVE UPDATE',
    'RUN INCREMENTAL UPDATE',
    'ROLLBACK LIVE UPDATE',
    'COMMIT LIVE UPDATE',
    'SHOW DEPENDENCY GRAPH',
    'SHOW AFFECTED OBJECTS',
    'SHOW RECONSTRUCTION ANALYTICS',
    'SHOW RECONSTRUCTION TIMELINE',
  ];
  const subjects = [
    'PIPELINE',
    'DEPENDENCY GRAPH',
    'AFFECTED REGIONS',
    'AFFECTED PATCHES',
    'AFFECTED BOUNDARIES',
    'AFFECTED CONTINUITY',
    'AFFECTED VALIDATION',
    'AFFECTED ANALYTICS',
    'REFLECTION UPDATE',
    'ZEBRA UPDATE',
    'DRAFT UPDATE',
    'HEAT MAP UPDATE',
    'LIVE ADVISOR',
    'DIRTY OBJECTS',
    'RECONSTRUCTION HISTORY',
    'INCREMENTAL SCHEDULER',
  ];
  const actions = [
    'SHOW',
    'LIST',
    'SELECT',
    'HIGHLIGHT',
    'INSPECT',
    'VALIDATE',
    'PREVIEW',
    'UPDATE',
    'ROLLBACK',
    'CANCEL',
    'COMMIT',
    'PERSIST',
    'EXPORT',
    'RESET',
    'REFRESH',
    'SHOW STATUS',
  ];
  final names = <String>{
    ...required,
    for (final subject in subjects)
      for (final action in actions) '$action $subject',
  };
  return [
    for (final name in names)
      LiveReconstructionFelCommand(name, api, operation, topology, quality),
  ];
}
