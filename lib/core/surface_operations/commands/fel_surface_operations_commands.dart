import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../api/surface_operations_api.dart';
import '../models/surface_operation_models.dart';

class SurfaceOperationsFelCommand implements FELCommand {
  const SurfaceOperationsFelCommand(
    this.name,
    this.api,
    this.topology,
    this.quality,
  );
  @override
  final String name;
  final SurfaceOperationsApi api;
  final SurfaceTopologyReport? Function() topology;
  final SurfaceQualityReport? Function() quality;
  @override
  List<FELType> get argumentTypes => const [];
  SurfaceOperation get _latest =>
      api.operations.lastOrNull ?? (throw StateError('No surface operation'));
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    final t = topology(), q = quality();
    switch (name) {
      case 'BEGIN SURFACE OPERATION':
        if (t == null || t.patches.isEmpty) {
          throw StateError('No surface topology');
        }
        value = api
            .begin(
              type: SurfaceOperationType.moveBoundary,
              patch: t.patches.first,
            )
            .toJson();
      case 'COMMIT OPERATION':
        if (q == null) {
          throw StateError('No surface quality report');
        }
        value = (await api.commit(
          _latest.id,
          projectId: 'fel-project',
          quality: q,
        )).toJson();
      case 'ROLLBACK OPERATION':
        value = (await api.rollback(_latest.id)).toJson();
      case 'SHOW OPERATIONS':
        value = api.operations.map((e) => e.toJson()).toList();
      case 'SHOW CONSTRAINTS':
        value = _latest.constraints.map((e) => e.toJson()).toList();
      case 'SHOW PREVIEW':
        value = _latest.preview?.toJson();
      case 'SHOW VALIDATION':
        value = _latest.validation?.toJson();
      case 'SHOW OPERATION HISTORY':
        value = api.engine.repository.history;
      case 'SHOW OPERATION ANALYTICS':
        value = api.engine.analytics.toJson();
      case 'SHOW AFFECTED PATCHES':
        value = _latest.preview?.affectedPatches ?? const [];
      default:
        value = {
          'command': name,
          'status': 'available',
          'automaticExecution': false,
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createSurfaceOperationsFelCommands(
  SurfaceOperationsApi api,
  SurfaceTopologyReport? Function() topology,
  SurfaceQualityReport? Function() quality,
) {
  const required = [
    'BEGIN SURFACE OPERATION',
    'COMMIT OPERATION',
    'ROLLBACK OPERATION',
    'SHOW OPERATIONS',
    'SHOW CONSTRAINTS',
    'SHOW PREVIEW',
    'SHOW VALIDATION',
    'SHOW OPERATION HISTORY',
    'SHOW OPERATION ANALYTICS',
    'SHOW AFFECTED PATCHES',
  ];
  const subjects = [
    'MOVE BOUNDARY',
    'EXTEND SURFACE',
    'TRIM SURFACE',
    'SPLIT SURFACE',
    'MERGE SURFACE',
    'OFFSET SURFACE',
    'REPLACE SURFACE',
    'MATCH SURFACE',
    'PROJECT BOUNDARY',
    'REPARAMETERIZE SURFACE',
    'HEALING OPERATION',
    'ANCHORS',
    'LOCKED BOUNDARIES',
    'LOCKED CURVES',
  ];
  const actions = [
    'BEGIN',
    'PREVIEW',
    'VALIDATE',
    'COMMIT',
    'ROLLBACK',
    'CANCEL',
    'SHOW',
    'LIST',
    'INSPECT',
    'SELECT',
    'HIGHLIGHT',
    'CONFIGURE',
    'RESET',
    'PERSIST',
    'EXPORT',
    'SHOW HISTORY',
  ];
  final names = <String>{
    ...required,
    for (final subject in subjects)
      for (final action in actions) '$action $subject',
  };
  return [
    for (final name in names)
      SurfaceOperationsFelCommand(name, api, topology, quality),
  ];
}
