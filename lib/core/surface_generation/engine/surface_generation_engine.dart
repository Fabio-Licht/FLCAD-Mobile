import '../../adaptive_surface/models/surface_geometry.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../engineering/history/engineering_history.dart';
import '../advisor/surface_generation_advisor.dart';
import '../analytics/surface_generation_analytics.dart';
import '../graph/generated_surface_graph.dart';
import '../history/surface_generation_history.dart';
import '../models/surface_generation_models.dart';
import '../registry/surface_registry.dart';
import '../repository/surface_generation_repository.dart';
import '../runtime/surface_generation_runtime.dart';
import '../validation/surface_generation_validator.dart';

class SurfaceGenerationEngine {
  SurfaceGenerationEngine({
    required this.projectId,
    required this.kernel,
    required this.repository,
    SurfaceGenerationRuntime? runtime,
    SurfaceGenerationHistory? history,
    SurfaceRegistry? registry,
    GeneratedSurfaceGraph? graph,
    SurfaceGenerationAnalytics? analytics,
    SurfaceGenerationValidator? validator,
    SurfaceGenerationAdvisor? advisor,
    this.engineeringGraph,
    this.engineeringHistory,
  }) : runtime = runtime ?? SurfaceGenerationRuntime(),
       history = history ?? SurfaceGenerationHistory(),
       registry = registry ?? SurfaceRegistry(),
       graph = graph ?? GeneratedSurfaceGraph(),
       analytics = analytics ?? SurfaceGenerationAnalytics(),
       validator = validator ?? const SurfaceGenerationValidator(),
       advisor = advisor ?? const SurfaceGenerationAdvisor();
  final String projectId;
  final GeometryKernelAPI kernel;
  final SurfaceGenerationRepository repository;
  final SurfaceGenerationRuntime runtime;
  final SurfaceGenerationHistory history;
  final SurfaceRegistry registry;
  final GeneratedSurfaceGraph graph;
  final SurfaceGenerationAnalytics analytics;
  final SurfaceGenerationValidator validator;
  final SurfaceGenerationAdvisor advisor;
  final EngineeringGraph? engineeringGraph;
  final EngineeringHistory? engineeringHistory;
  Future<SurfaceGenerationResult> generate(
    SurfaceGenerationRequest request,
  ) => runtime.execute(request.candidate.kind.name, () async {
    final stages = <SurfacePipelineStage>[],
        allDiagnostics = <GeometryDiagnostic>[],
        generationWatch = Stopwatch(),
        validationWatch = Stopwatch()..start(),
        healingWatch = Stopwatch();
    final pre = validator.validate(request);
    validationWatch.stop();
    stages.add(SurfacePipelineStage.candidateValidation);
    allDiagnostics.addAll(pre);
    if (pre.any((e) => e.severity == 'error')) {
      return _finishAttempt(
        request,
        SurfaceGenerationStatus.invalid,
        allDiagnostics,
        stages,
        Duration.zero,
        validationWatch.elapsed,
        Duration.zero,
      );
    }
    final capability = _capability(request.candidate.kind);
    await kernel.healthCheck();
    if (!kernel.descriptor.capabilities.supports(capability)) {
      allDiagnostics.add(
        GeometryDiagnostic(
          code: 'backend-unavailable',
          message:
              '${request.candidate.kind.name} generation is unavailable in kernel ${kernel.descriptor.id}',
          severity: 'error',
        ),
      );
      stages.add(SurfacePipelineStage.geometryBuilder);
      return _finishAttempt(
        request,
        SurfaceGenerationStatus.unavailable,
        allDiagnostics,
        stages,
        Duration.zero,
        validationWatch.elapsed,
        Duration.zero,
      );
    }
    final transactions = KernelTransactionManager(kernel),
        transaction = await transactions.begin(projectId);
    try {
      generationWatch.start();
      final handle = await kernel.create(
        'GENERATE ${request.candidate.kind.name.toUpperCase()}',
        request.parameters,
        persistentId:
            '$projectId-surface-${DateTime.now().microsecondsSinceEpoch}',
        expectedType: CADShapeType.face,
        transaction: transaction,
      );
      generationWatch.stop();
      stages.add(SurfacePipelineStage.geometryBuilder);
      validationWatch.start();
      final shapeDiagnostics = (await kernel.validate(handle, const {
        'geometry',
        'bounds',
        'region',
        'continuity',
        'tolerance',
        'orientation',
        'degeneration',
      })).map(_diagnostic).toList();
      validationWatch.stop();
      allDiagnostics.addAll(shapeDiagnostics);
      stages.add(SurfacePipelineStage.shapeValidation);
      if (shapeDiagnostics.any((e) => e.severity == 'error')) {
        await transactions.rollback(transaction.id);
        return _finishAttempt(
          request,
          SurfaceGenerationStatus.failed,
          allDiagnostics,
          stages,
          generationWatch.elapsed,
          validationWatch.elapsed,
          Duration.zero,
        );
      }
      healingWatch.start();
      List<HealingProposal> proposals = [];
      final sewing = <String>[], repair = <String>[];
      if (kernel is InterchangeGeometryKernelAPI) {
        final api = kernel as InterchangeGeometryKernelAPI;
        allDiagnostics.addAll(await api.diagnose(handle));
        proposals = await api.proposeHealing(handle);
        if (request.candidate.boundaries.isNotEmpty) {
          sewing.add('Review sewing with neighboring generated faces');
        }
        if (allDiagnostics.isNotEmpty) {
          repair.add('Review repair proposal for reported diagnostics');
        }
      } else {
        allDiagnostics.add(
          const GeometryDiagnostic(
            code: 'healing-contract-unavailable',
            message: 'Active kernel does not expose healing proposals',
            severity: 'warning',
          ),
        );
      }
      healingWatch.stop();
      stages.add(SurfacePipelineStage.healingProposal);
      if (allDiagnostics.any((e) => e.severity == 'error')) {
        await transactions.rollback(transaction.id);
        return _finishAttempt(
          request,
          SurfaceGenerationStatus.failed,
          allDiagnostics,
          stages,
          generationWatch.elapsed,
          validationWatch.elapsed,
          healingWatch.elapsed,
          proposals: proposals,
          sewing: sewing,
          repair: repair,
        );
      }
      await transactions.commit(transaction.id);
      final surface = GeneratedSurface(
        surfaceId: 'surface-${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        kind: request.candidate.kind,
        origin: request.origin,
        regionIds: request.candidate.regionIds,
        evidenceIds: request.candidate.evidence.map((e) => e.id).toList(),
        featureId: request.featureId,
        handle: handle,
        revision: 1,
        timestamp: DateTime.now(),
        parameters: request.parameters,
        continuity: request.candidate.predictedContinuity,
        valid: true,
        confidence: request.candidate.confidence,
        diagnostics: allDiagnostics,
      );
      registry.register(surface);
      stages.add(SurfacePipelineStage.registration);
      graph.add(surface);
      _registerEngineering(surface);
      stages.add(SurfacePipelineStage.engineeringGraph);
      history.record(
        SurfaceGenerationHistoryAction.generate,
        request.candidate.id,
        SurfaceGenerationStatus.generated,
        allDiagnostics.map((e) => e.code).toList(),
        surfaceId: surface.surfaceId,
      );
      stages.add(SurfacePipelineStage.history);
      analytics.record(
        SurfaceGenerationMetric(
          surface.kind,
          generationWatch.elapsed,
          validationWatch.elapsed,
          healingWatch.elapsed,
          true,
          request.candidate.coverage,
        ),
      );
      stages.add(SurfacePipelineStage.analytics);
      await repository.save(surface, graph);
      return SurfaceGenerationResult(
        status: SurfaceGenerationStatus.generated,
        surface: surface,
        diagnostics: allDiagnostics,
        completedStages: stages,
        healingProposals: proposals,
        sewingSuggestions: sewing,
        repairSuggestions: repair,
      );
    } catch (error) {
      try {
        await transactions.rollback(transaction.id);
      } catch (_) {}
      allDiagnostics.add(
        GeometryDiagnostic(
          code: 'kernel-generation-failed',
          message: error.toString(),
          severity: 'error',
        ),
      );
      return _finishAttempt(
        request,
        SurfaceGenerationStatus.failed,
        allDiagnostics,
        stages,
        generationWatch.elapsed,
        validationWatch.elapsed,
        healingWatch.elapsed,
      );
    }
  });
  Future<SurfaceGenerationResult> _finishAttempt(
    SurfaceGenerationRequest request,
    SurfaceGenerationStatus status,
    List<GeometryDiagnostic> diagnostics,
    List<SurfacePipelineStage> stages,
    Duration generation,
    Duration validation,
    Duration healing, {
    List<HealingProposal> proposals = const [],
    List<String> sewing = const [],
    List<String> repair = const [],
  }) async {
    history.record(
      switch (status) {
        SurfaceGenerationStatus.invalid =>
          SurfaceGenerationHistoryAction.invalid,
        SurfaceGenerationStatus.unavailable =>
          SurfaceGenerationHistoryAction.unavailable,
        _ => SurfaceGenerationHistoryAction.failed,
      },
      request.candidate.id,
      status,
      diagnostics.map((e) => e.code).toList(),
    );
    stages.add(SurfacePipelineStage.history);
    analytics.record(
      SurfaceGenerationMetric(
        request.candidate.kind,
        generation,
        validation,
        healing,
        false,
        request.candidate.coverage,
      ),
    );
    stages.add(SurfacePipelineStage.analytics);
    await repository.saveAttempt(request.candidate.id, status, diagnostics);
    return SurfaceGenerationResult(
      status: status,
      diagnostics: diagnostics,
      completedStages: stages,
      healingProposals: proposals,
      sewingSuggestions: sewing,
      repairSuggestions: repair,
    );
  }

  KernelCapability _capability(SurfaceKind kind) => switch (kind) {
    SurfaceKind.plane => KernelCapability.planeSurface,
    SurfaceKind.cylinder => KernelCapability.cylinderSurface,
    SurfaceKind.cone => KernelCapability.coneSurface,
    SurfaceKind.sphere => KernelCapability.sphereSurface,
    SurfaceKind.torus => KernelCapability.torusSurface,
    _ => throw UnsupportedError('${kind.name} is outside G-005B'),
  };
  GeometryDiagnostic _diagnostic(String value) {
    final parts = value.split(':');
    return GeometryDiagnostic(
      code: parts.length > 2 ? parts[1] : 'kernel-validation',
      message: parts.length > 2 ? parts.sublist(2).join(':') : value,
      severity: parts.length > 2 ? parts[0] : 'error',
    );
  }

  void _registerEngineering(GeneratedSurface surface) {
    engineeringHistory?.record(
      projectId: projectId,
      entityId: surface.surfaceId,
      domain: 'surface-generation',
      action: 'generate',
      snapshot: surface.toJson(),
    );
    final target = engineeringGraph;
    if (target == null) return;
    target.addNode(
      EngineeringGraphNode(
        surface.surfaceId,
        EngineeringNodeType.surface,
        metadata: {
          'kind': surface.kind.name,
          'shapeId': surface.handle.persistentId,
        },
      ),
    );
    for (final region in surface.regionIds) {
      target.addNode(EngineeringGraphNode(region, EngineeringNodeType.region));
      target.connect(
        EngineeringGraphEdge(region, surface.surfaceId, 'source-region'),
      );
    }
  }

  Future<void> delete(String id) async {
    final surface = registry.remove(id);
    if (surface == null) return;
    await repository.delete(id);
    history.record(
      SurfaceGenerationHistoryAction.delete,
      id,
      SurfaceGenerationStatus.generated,
      const [],
      surfaceId: id,
    );
  }
}
