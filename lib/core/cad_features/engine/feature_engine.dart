import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../engineering/history/engineering_history.dart';
import '../graph/feature_graph.dart';
import '../history/feature_history.dart';
import '../models/feature_models.dart';
import '../repository/feature_repository.dart';
import '../runtime/feature_runtime.dart';

class FeatureEngine {
  FeatureEngine({
    required this.projectId,
    required this.kernel,
    required this.repository,
    FeatureRuntime? runtime,
    FeatureHistory? history,
    FeatureGraph? graph,
    this.engineeringHistory,
    this.engineeringGraph,
  }) : runtime = runtime ?? FeatureRuntime(),
       history = history ?? FeatureHistory(),
       graph = graph ?? FeatureGraph();
  final String projectId;
  final GeometryKernelAPI kernel;
  final FeatureRepository repository;
  final FeatureRuntime runtime;
  final FeatureHistory history;
  final FeatureGraph graph;
  final EngineeringHistory? engineeringHistory;
  final EngineeringGraph? engineeringGraph;
  Future<FeatureResult> execute(
    CadFeatureKind kind,
    List<ShapeHandle> inputs,
    Map<String, dynamic> parameters, {
    List<String> dependencies = const [],
    String user = 'local',
    Map<String, dynamic> humanDecisions = const {},
  }) => _perform(
    kind,
    inputs,
    parameters,
    dependencies: dependencies,
    user: user,
    humanDecisions: humanDecisions,
  );
  Future<FeatureResult> _perform(
    CadFeatureKind kind,
    List<ShapeHandle> inputs,
    Map<String, dynamic> parameters, {
    required List<String> dependencies,
    required String user,
    required Map<String, dynamic> humanDecisions,
    String? featureId,
    int revision = 1,
    FeatureHistoryAction action = FeatureHistoryAction.create,
  }) => runtime.execute(kind.name, () async {
    if (inputs.isEmpty) {
      return FeatureResult(
        _failure(
          kind,
          inputs,
          parameters,
          dependencies,
          user,
          'missing-input',
          'Feature requires at least one ShapeHandle',
          featureId: featureId,
          revision: revision,
        ),
      );
    }
    final capability = _capability(kind);
    if (!kernel.descriptor.capabilities.supports(capability)) {
      final feature = _failure(
        kind,
        inputs,
        parameters,
        dependencies,
        user,
        'backend-unavailable',
        '${kind.name} is unavailable in kernel ${kernel.descriptor.id}',
        featureId: featureId,
        revision: revision,
        status: CadFeatureStatus.unavailable,
        humanDecisions: humanDecisions,
      );
      history.record(FeatureHistoryAction.unavailable, feature);
      _recordEngineering(feature, 'unavailable');
      return FeatureResult(feature);
    }
    final watch = Stopwatch()..start();
    final transactions = KernelTransactionManager(kernel);
    final transaction = await transactions.begin(projectId);
    try {
      final output = await kernel.create(
        _operation(kind),
        {'inputs': inputs, ...parameters},
        persistentId:
            '$projectId-feature-${DateTime.now().microsecondsSinceEpoch}',
        expectedType: _outputType(kind, inputs.first),
        transaction: transaction,
      );
      final diagnostics = (await kernel.validate(
        output,
        _validationChecks,
      )).map(_diagnostic).toList();
      if (diagnostics.any((e) => e.severity == 'error')) {
        await transactions.rollback(transaction.id);
        final feature = _failure(
          kind,
          inputs,
          parameters,
          dependencies,
          user,
          'validation-failed',
          'Kernel rejected feature output',
          featureId: featureId,
          revision: revision,
          diagnostics: diagnostics,
          humanDecisions: humanDecisions,
        );
        history.record(FeatureHistoryAction.fail, feature);
        _recordEngineering(feature, 'validation-failed');
        return FeatureResult(feature);
      }
      await transactions.commit(transaction.id);
      watch.stop();
      final feature = CadFeature(
        id:
            featureId ??
            '$projectId-${kind.name}-${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        kind: kind,
        inputs: inputs,
        output: output,
        parameters: parameters,
        dependencies: dependencies,
        createdAt: DateTime.now(),
        user: user,
        revision: revision,
        status: CadFeatureStatus.valid,
        buildTime: watch.elapsed,
        diagnostics: diagnostics,
        humanDecisions: humanDecisions,
      );
      graph.add(feature);
      history.record(action, feature);
      _recordEngineering(feature, action.name);
      await repository.save(feature);
      await repository.saveGraph(graph);
      return FeatureResult(feature);
    } catch (error) {
      try {
        await transactions.rollback(transaction.id);
      } catch (_) {}
      rethrow;
    }
  });
  Future<List<FeatureResult>> rebuild(
    String changedShapeId,
    ShapeHandle replacement,
  ) async {
    final affected = graph.affectedByShape(changedShapeId);
    final replacements = <String, ShapeHandle>{changedShapeId: replacement};
    final results = <FeatureResult>[];
    for (final feature
        in graph.nodes.values.where((e) => affected.contains(e.id)).toList()) {
      final inputs = feature.inputs
          .map((e) => replacements[e.persistentId] ?? e)
          .toList();
      final result = await _perform(
        feature.kind,
        inputs,
        feature.parameters,
        dependencies: feature.dependencies,
        user: feature.user,
        humanDecisions: feature.humanDecisions,
        featureId: feature.id,
        revision: feature.revision + 1,
        action: FeatureHistoryAction.rebuild,
      );
      results.add(result);
      if (result.success && feature.output != null) {
        replacements[feature.output!.persistentId] = result.feature.output!;
      }
    }
    return results;
  }

  Future<HealingAudit> healing(ShapeHandle shape) async {
    if (kernel is! InterchangeGeometryKernelAPI) {
      throw StateError('Active kernel does not support healing');
    }
    final api = kernel as InterchangeGeometryKernelAPI;
    final problems = await api.diagnose(shape);
    final proposals = await api.proposeHealing(shape);
    return HealingAudit(
      shape: shape,
      problems: problems,
      proposed: proposals,
      executed: const [],
    );
  }

  Future<List<GeometryDiagnostic>> validateSolid(ShapeHandle shape) async {
    if (shape.type != CADShapeType.solid) {
      return const [
        GeometryDiagnostic(
          code: 'not-solid',
          message: 'Shape is not a solid',
          severity: 'error',
        ),
      ];
    }
    if (kernel is InterchangeGeometryKernelAPI) {
      return (kernel as InterchangeGeometryKernelAPI).diagnose(shape);
    }
    return (await kernel.validate(
      shape,
      _validationChecks,
    )).map(_diagnostic).toList();
  }

  CadFeature _failure(
    CadFeatureKind kind,
    List<ShapeHandle> inputs,
    Map<String, dynamic> parameters,
    List<String> dependencies,
    String user,
    String code,
    String message, {
    String? featureId,
    int revision = 1,
    CadFeatureStatus status = CadFeatureStatus.failed,
    List<GeometryDiagnostic>? diagnostics,
    Map<String, dynamic> humanDecisions = const {},
  }) => CadFeature(
    id:
        featureId ??
        '$projectId-${kind.name}-${DateTime.now().microsecondsSinceEpoch}',
    projectId: projectId,
    kind: kind,
    inputs: inputs,
    output: null,
    parameters: parameters,
    dependencies: dependencies,
    createdAt: DateTime.now(),
    user: user,
    revision: revision,
    status: status,
    buildTime: Duration.zero,
    diagnostics:
        diagnostics ??
        [GeometryDiagnostic(code: code, message: message, severity: 'error')],
    humanDecisions: humanDecisions,
  );
  KernelCapability _capability(CadFeatureKind kind) => switch (kind) {
    CadFeatureKind.extrude => KernelCapability.extrude,
    CadFeatureKind.revolve => KernelCapability.revolve,
    CadFeatureKind.sweep => KernelCapability.sweep,
    CadFeatureKind.loft => KernelCapability.loft,
    CadFeatureKind.booleanUnion ||
    CadFeatureKind.booleanSubtract ||
    CadFeatureKind.booleanIntersect => KernelCapability.boolean,
    CadFeatureKind.offset => KernelCapability.offset,
    CadFeatureKind.shell => KernelCapability.shell,
    CadFeatureKind.draft => KernelCapability.draft,
    CadFeatureKind.mirror => KernelCapability.mirror,
    CadFeatureKind.linearPattern => KernelCapability.linearPattern,
    CadFeatureKind.circularPattern => KernelCapability.circularPattern,
  };
  String _operation(CadFeatureKind kind) => switch (kind) {
    CadFeatureKind.booleanUnion => 'BOOLEAN UNION',
    CadFeatureKind.booleanSubtract => 'BOOLEAN SUBTRACT',
    CadFeatureKind.booleanIntersect => 'BOOLEAN INTERSECT',
    _ => kind.name.toUpperCase(),
  };
  CADShapeType _outputType(CadFeatureKind kind, ShapeHandle input) =>
      switch (kind) {
        CadFeatureKind.extrude ||
        CadFeatureKind.revolve ||
        CadFeatureKind.sweep ||
        CadFeatureKind.loft ||
        CadFeatureKind.booleanUnion ||
        CadFeatureKind.booleanSubtract ||
        CadFeatureKind.booleanIntersect => CADShapeType.solid,
        _ => input.type,
      };
  static const _validationChecks = {
    'open-wire',
    'self-intersection',
    'duplicated-edge',
    'non-manifold',
    'invalid-shell',
    'invalid-solid',
    'tiny-edges',
    'degenerated-faces',
    'inconsistent-orientation',
  };
  GeometryDiagnostic _diagnostic(String value) {
    final parts = value.split(':');
    return GeometryDiagnostic(
      severity: parts.length > 2 ? parts[0] : 'error',
      code: parts.length > 2 ? parts[1] : 'kernel-validation',
      message: parts.length > 2 ? parts.sublist(2).join(':') : value,
    );
  }

  void _recordEngineering(CadFeature feature, String action) {
    engineeringHistory?.record(
      projectId: projectId,
      entityId: feature.id,
      domain: 'cad-features',
      action: action,
      snapshot: feature.toJson(),
    );
    final target = engineeringGraph;
    if (target == null) return;
    target.addNode(
      EngineeringGraphNode(
        feature.id,
        EngineeringNodeType.feature,
        metadata: {'kind': feature.kind.name, 'revision': feature.revision},
      ),
    );
    for (final input in feature.inputs) {
      target.addNode(
        EngineeringGraphNode(input.persistentId, _engineeringType(input)),
      );
      target.connect(
        EngineeringGraphEdge(input.persistentId, feature.id, 'input'),
      );
    }
    final output = feature.output;
    if (output != null) {
      target.addNode(
        EngineeringGraphNode(output.persistentId, _engineeringType(output)),
      );
      target.connect(
        EngineeringGraphEdge(feature.id, output.persistentId, 'output'),
      );
    }
  }

  EngineeringNodeType _engineeringType(ShapeHandle shape) =>
      switch (shape.type) {
        CADShapeType.face => EngineeringNodeType.surface,
        CADShapeType.solid => EngineeringNodeType.solid,
        _ => EngineeringNodeType.topology,
      };
}
