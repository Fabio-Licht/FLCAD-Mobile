import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/graph/geometry_graph.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../history/cad_builder_history.dart';
import '../models/cad_models.dart';
import '../repository/cad_builder_repository.dart';
import '../runtime/cad_builder_runtime.dart';

class CadBuilderEngine {
  CadBuilderEngine({
    required this.projectId,
    required this.kernel,
    required this.repository,
    CadBuilderRuntime? runtime,
    CadBuilderHistory? history,
    GeometryGraph? graph,
  }) : runtime = runtime ?? CadBuilderRuntime(),
       history = history ?? CadBuilderHistory(),
       graph = graph ?? GeometryGraph();
  final String projectId;
  final GeometryKernelAPI kernel;
  final CadBuilderRepository repository;
  final CadBuilderRuntime runtime;
  final CadBuilderHistory history;
  final GeometryGraph graph;

  Future<CadBuildResult> build(
    CADShapeType type,
    String operation,
    Map<String, dynamic> parameters,
    List<ShapeHandle> dependencies, {
    String origin = 'user',
  }) => runtime.execute(operation, () async {
    if (type == CADShapeType.solid) {
      final shell = dependencies.singleOrNull;
      if (shell == null ||
          shell.type != CADShapeType.shell ||
          shell.metadata['closed'] != true) {
        return const CadBuildResult(
          diagnostics: [
            GeometryDiagnostic(
              code: 'shell-not-closed',
              message: 'Solid requires a completely closed shell',
              severity: 'error',
            ),
          ],
        );
      }
    }
    final transactions = KernelTransactionManager(kernel);
    final transaction = await transactions.begin(projectId);
    try {
      final handle = await kernel.create(
        operation,
        parameters,
        persistentId:
            '$projectId-${type.name}-${DateTime.now().microsecondsSinceEpoch}',
        expectedType: type,
        transaction: transaction,
      );
      final raw = await kernel.validate(handle, _checks(type));
      final diagnostics = raw.map(_diagnostic).toList();
      final valid = diagnostics.every((e) => e.severity != 'error');
      if (!valid) {
        await transactions.rollback(transaction.id);
        return CadBuildResult(diagnostics: diagnostics);
      }
      await transactions.commit(transaction.id);
      final entity = CadEntity(
        handle: handle,
        projectId: projectId,
        origin: origin,
        dependencies: dependencies.map((e) => e.persistentId).toList(),
        valid: true,
        diagnostics: diagnostics,
        createdAt: DateTime.now(),
        statistics: {'kernel': kernel.descriptor.id},
      );
      graph.add(GeometryGraphNode(handle, {'origin': origin, 'valid': true}));
      for (final dependency in dependencies) {
        if (!graph.nodes.containsKey(dependency.persistentId)) {
          graph.add(GeometryGraphNode(dependency, const {}));
        }
        graph.connect(
          GeometryGraphEdge(
            dependency.persistentId,
            handle.persistentId,
            'builds',
          ),
        );
      }
      await repository.save(entity);
      await repository.saveTopology(_topologyJson());
      history.record(CadHistoryAction.create, entity);
      return CadBuildResult(entity: entity, diagnostics: diagnostics);
    } catch (_) {
      await transactions.rollback(transaction.id);
      rethrow;
    }
  });
  Set<String> _checks(CADShapeType type) => switch (type) {
    CADShapeType.vertex => {'degeneration'},
    CADShapeType.edge => {'degeneration'},
    CADShapeType.wire => {'closure', 'orientation'},
    CADShapeType.face => {'closure', 'orientation', 'degeneration'},
    CADShapeType.shell || CADShapeType.solid => {
      'manifold',
      'closure',
      'orientation',
      'degeneration',
    },
    CADShapeType.compound => {'validity'},
  };
  GeometryDiagnostic _diagnostic(String value) {
    final parts = value.split(':');
    return GeometryDiagnostic(
      severity: parts.length > 2 ? parts[0] : 'error',
      code: parts.length > 2 ? parts[1] : 'kernel-validation',
      message: parts.length > 2 ? parts.sublist(2).join(':') : value,
    );
  }

  Map<String, dynamic> _topologyJson() => {
    'nodes': graph.nodes.values.map((e) => e.handle.toJson()).toList(),
    'edges': graph.edges
        .map(
          (e) => {
            'source': e.sourceId,
            'target': e.targetId,
            'relation': e.relation,
          },
        )
        .toList(),
  };
  Future<void> delete(String id) async {
    final entity = (await repository.loadAll())
        .where((e) => e.handle.persistentId == id)
        .firstOrNull;
    if (entity == null) return;
    await repository.delete(id);
    history.record(CadHistoryAction.delete, entity);
  }

  Future<CadEntity?> undo() async {
    final entry = history.undoCandidate();
    if (entry == null) return null;
    await repository.delete(entry.entity.handle.persistentId);
    history.record(CadHistoryAction.undo, entry.entity);
    return entry.entity;
  }
}
