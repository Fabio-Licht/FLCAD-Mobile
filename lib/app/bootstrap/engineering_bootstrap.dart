import 'dart:io';

import '../../core/autonomous_reconstruction/api/autonomous_reconstruction_api.dart';
import '../../core/engineering/cache/engineering_cache.dart';
import '../../core/engineering/commands/engineering_command_bus.dart';
import '../../core/engineering/configuration/engineering_configuration.dart';
import '../../core/engineering/context/engineering_context.dart';
import '../../core/engineering/events/engineering_event_bus.dart';
import '../../core/engineering/graph/engineering_graph.dart';
import '../../core/engineering/history/engineering_history.dart';
import '../../core/engineering/kernel/engineering_kernel.dart';
import '../../core/engineering/learning/engineering_learning.dart';
import '../../core/engineering/plugins/plugin_registry.dart';
import '../../core/engineering/queries/engineering_query_bus.dart';
import '../../core/engineering/runtime/engineering_runtime.dart';
import '../../core/engineering/serialization/schema_registry.dart';
import '../../core/engineering/services/engineering_service_registry.dart';
import '../../core/engineering_cognition/api/engineering_cognition_api.dart';
import '../../core/engineering_decision/api/decision_api.dart';
import '../../core/engineering_decision/engine/engineering_decision_engine.dart';
import '../../core/engineering_decision/memory/decision_memory.dart';
import '../../core/engineering_reconstruction/api/engineering_reconstruction_api.dart';
import '../../core/engineering_reconstruction/planner/engineering_reconstruction_planner.dart';
import '../../core/cad_kernel/manager/kernel_manager.dart';
import '../../core/cad_kernel/opencascade/open_cascade_kernel_plugin.dart';
import '../../core/cad_builder/integration/cad_builder_factory.dart';
import '../../core/cad_features/integration/feature_factory.dart';
import '../../core/surface_intelligence/integration/surface_factory.dart';
import '../../core/surface_generation/integration/surface_generation_factory.dart';
import '../../core/hybrid_surface_engine/integration/hybrid_surface_factory.dart';
import '../../core/engineering_knowledge/api/engineering_knowledge_api.dart';
import '../../core/geometric_kernel/api/geometric_kernel_api.dart';
import '../../core/geometric_recognition/api/recognition_api.dart';
import '../../core/geometric_recognition/engine/geometric_recognition_engine.dart';
import '../../core/professional_recognition/api/professional_recognition_api.dart';
import '../../core/professional_recognition/engine/professional_recognition_engine.dart';
import '../../core/reverse_intelligence/api/reverse_intelligence_api.dart';
import '../../core/sketch_engine/analytics/sketch_analytics.dart';
import '../../core/sketch_engine/history/sketch_history.dart';
import '../../core/sketch_engine/integration/sketch_factory.dart';
import '../../core/sketch_engine/repository/sketch_repository.dart';
import '../../core/sketch_engine/runtime/sketch_runtime.dart';
import '../../core/sketch_constraints/analytics/constraint_analytics.dart';
import '../../core/sketch_constraints/history/constraint_history.dart';
import '../../core/sketch_constraints/integration/constraint_factory.dart';
import '../../core/sketch_constraints/repository/constraint_repository.dart';
import '../../core/sketch_constraints/runtime/constraint_runtime.dart';
import '../../core/sketch_editor/analytics/editor_analytics.dart';
import '../../core/sketch_editor/history/editor_history.dart';
import '../../core/sketch_editor/integration/editor_factory.dart';
import '../../core/sketch_editor/repository/editor_repository.dart';
import '../../core/sketch_editor/runtime/editor_runtime.dart';
import '../../core/profile_recognition/analytics/profile_analytics.dart';
import '../../core/profile_recognition/history/profile_history.dart';
import '../../core/profile_recognition/integration/profile_factory.dart';
import '../../core/profile_recognition/repository/profile_repository.dart';
import '../../core/profile_recognition/runtime/profile_runtime.dart';
import '../../core/feature_modeling/analytics/feature_analytics.dart';
import '../../core/feature_modeling/history/feature_history.dart';
import '../../core/feature_modeling/integration/feature_modeling_factory.dart';
import '../../core/feature_modeling/repository/feature_repository.dart';
import '../../core/feature_modeling/runtime/feature_runtime.dart';
import '../../core/extrude_feature/analytics/extrude_analytics.dart';
import '../../core/extrude_feature/history/extrude_history.dart';
import '../../core/extrude_feature/integration/extrude_factory.dart';
import '../../core/extrude_feature/repository/extrude_repository.dart';
import '../../core/extrude_feature/runtime/extrude_runtime.dart';
import '../../core/revolve_feature/analytics/revolve_analytics.dart';
import '../../core/revolve_feature/history/revolve_history.dart';
import '../../core/revolve_feature/integration/revolve_factory.dart';
import '../../core/revolve_feature/repository/revolve_repository.dart';
import '../../core/revolve_feature/runtime/revolve_runtime.dart';
import '../../core/transition_features/analytics/transition_analytics.dart';
import '../../core/transition_features/history/transition_history.dart';
import '../../core/transition_features/integration/transition_factory.dart';
import '../../core/transition_features/repository/transition_repository.dart';
import '../../core/transition_features/runtime/transition_runtime.dart';
import '../../core/reference_geometry/analytics/reference_analytics.dart';
import '../../core/reference_geometry/history/reference_history.dart';
import '../../core/reference_geometry/integration/reference_factory.dart';
import '../../core/reference_geometry/repository/reference_repository.dart';
import '../../core/reference_geometry/runtime/reference_runtime.dart';
import '../../core/alignment_engine/analytics/alignment_analytics.dart';
import '../../core/alignment_engine/history/alignment_history.dart';
import '../../core/alignment_engine/integration/alignment_factory.dart';
import '../../core/alignment_engine/repository/alignment_repository.dart';
import '../../core/alignment_engine/runtime/alignment_runtime.dart';
import '../../core/live_validation/analytics/validation_analytics.dart';
import '../../core/live_validation/history/validation_history.dart';
import '../../core/live_validation/history/validation_timeline.dart';
import '../../core/live_validation/integration/validation_factory.dart';
import '../../core/live_validation/repository/validation_repository.dart';
import '../../core/live_validation/runtime/live_validation_runtime.dart';
import '../../core/engineering_intelligence/analytics/intelligence_analytics.dart';
import '../../core/engineering_intelligence/history/intelligence_history.dart';
import '../../core/engineering_intelligence/integration/intelligence_factory.dart';
import '../../core/engineering_intelligence/repository/intelligence_repository.dart';
import '../../core/engineering_intelligence/runtime/intelligence_runtime.dart';
import '../../core/reverse_workflow/analytics/workflow_analytics.dart';
import '../../core/reverse_workflow/history/workflow_history.dart';
import '../../core/reverse_workflow/history/workflow_timeline.dart';
import '../../core/reverse_workflow/integration/workflow_factory.dart';
import '../../core/reverse_workflow/repository/workflow_repository.dart';
import '../../core/reverse_workflow/runtime/reverse_workflow_runtime.dart';
import '../../core/adaptive_studio/analytics/workspace_analytics.dart';
import '../../core/adaptive_studio/history/workspace_history.dart';
import '../../core/adaptive_studio/integration/adaptive_studio_factory.dart';
import '../../core/adaptive_studio/repository/adaptive_studio_repository.dart';
import '../../core/adaptive_studio/runtime/adaptive_studio_runtime.dart';
import '../../core/interactive_reverse/analytics/interactive_analytics.dart';
import '../../core/interactive_reverse/history/interactive_history.dart';
import '../../core/interactive_reverse/integration/interactive_reverse_factory.dart';
import '../../core/interactive_reverse/repository/interactive_reverse_repository.dart';
import '../../core/interactive_reverse/runtime/interactive_reverse_runtime.dart';
import '../../core/reverse_session/analytics/session_analytics.dart';
import '../../core/reverse_session/history/session_history.dart';
import '../../core/reverse_session/integration/reverse_session_factory.dart';
import '../../core/reverse_session/journal/reverse_journal.dart';
import '../../core/reverse_session/repository/reverse_session_repository.dart';
import '../../core/reverse_session/runtime/reverse_session_runtime.dart';
import '../../core/reverse_session/timeline/session_timeline.dart';
import '../../core/platform_certification/analytics/certification_analytics.dart';
import '../../core/platform_certification/history/certification_history.dart';
import '../../core/platform_certification/integration/platform_certification_factory.dart';
import '../../core/platform_certification/repository/platform_certification_repository.dart';
import '../../core/platform_certification/runtime/platform_certification_runtime.dart';
import '../../core/mesh_foundation/analytics/mesh_analytics.dart';
import '../../core/mesh_foundation/integration/mesh_factory.dart';
import '../../core/mesh_foundation/repository/mesh_repository.dart';
import '../../core/mesh_foundation/runtime/mesh_runtime.dart';
import '../../core/surface_recognition/integration/surface_recognition_factory.dart';
import '../../core/surface_recognition/repository/surface_recognition_repository.dart';
import '../../core/surface_recognition/runtime/surface_recognition_runtime.dart';
import '../../core/surface_fitting/integration/surface_fitting_factory.dart';
import '../../core/surface_fitting/repository/surface_fitting_repository.dart';
import '../../core/surface_fitting/runtime/surface_fitting_runtime.dart';
import '../../core/surface_topology/integration/surface_topology_factory.dart';
import '../../core/surface_topology/repository/surface_topology_repository.dart';
import '../../core/surface_topology/runtime/surface_topology_runtime.dart';
import '../../core/surface_continuity/integration/surface_continuity_factory.dart';
import '../../core/surface_continuity/repository/surface_continuity_repository.dart';
import '../../core/surface_continuity/runtime/surface_continuity_runtime.dart';
import '../../core/surface_operations/integration/surface_operations_factory.dart';
import '../../core/surface_operations/repository/surface_operation_repository.dart';
import '../../core/surface_operations/runtime/surface_operations_runtime.dart';
import '../../core/live_reconstruction/integration/live_reconstruction_factory.dart';
import '../../core/live_reconstruction/repository/live_reconstruction_repository.dart';
import '../../core/live_reconstruction/runtime/live_reconstruction_runtime.dart';
import '../../core/surface_morph/integration/surface_morph_factory.dart';
import '../../core/surface_morph/repository/surface_morph_repository.dart';
import '../../core/surface_morph/runtime/surface_morph_runtime.dart';
import '../../core/surface_extend/integration/surface_extend_factory.dart';
import '../../core/surface_extend/repository/surface_extend_repository.dart';
import '../../core/surface_extend/runtime/surface_extend_runtime.dart';

/// Application composition root. Concrete engines are wired here, outside the
/// engineering core, so the core depends only on its contracts.
class EngineeringBootstrap {
  EngineeringBootstrap._();
  static final instance = EngineeringBootstrap._();

  final runtime = EngineeringRuntime.shared;
  final cache = EngineeringCache();
  final schemas = SchemaRegistry();
  final plugins = EngineeringPluginRegistry();
  final services = EngineeringServiceRegistry();
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    services
      ..register<EngineeringRuntime>(runtime)
      ..register<EngineeringCache>(cache)
      ..register<SchemaRegistry>(schemas)
      ..register<EngineeringPluginRegistry>(plugins)
      ..register<GeometricKernelApi>(const GeometricKernelApi())
      ..register<ReverseIntelligenceApi>(ReverseIntelligenceApi())
      ..register<EngineeringKnowledgeApi>(EngineeringKnowledgeApi())
      ..register<EngineeringCognitionApi>(EngineeringCognitionApi())
      ..register<AutonomousReconstructionApi>(AutonomousReconstructionApi());
    services.register<DecisionApi>(
      DecisionApi(
        engine: EngineeringDecisionEngine(
          memory: DecisionMemory(ProjectDecisionMemoryStore()),
        ),
      ),
    );
    services.register<RecognitionApi>(
      RecognitionApi(
        engine: GeometricRecognitionEngine(
          decisions: services.get<DecisionApi>(),
        ),
      ),
    );
    services.register<ProfessionalRecognitionApi>(
      ProfessionalRecognitionApi(
        engine: ProfessionalRecognitionEngine(
          decisions: services.get<DecisionApi>(),
        ),
      ),
    );
    services.register<EngineeringReconstructionApi>(
      EngineeringReconstructionApi(
        planner: EngineeringReconstructionPlanner(
          decisions: services.get<DecisionApi>(),
        ),
      ),
    );
    final kernelManager = KernelManager();
    OpenCascadeKernelPlugin().register(kernelManager);
    services.register<KernelManager>(kernelManager);
    services.register<CadBuilderFactory>(CadBuilderFactory(kernelManager));
    services.register<FeatureFactory>(FeatureFactory(kernelManager));
    services.register<SurfaceIntelligenceFactory>(
      const SurfaceIntelligenceFactory(),
    );
    services.register<SurfaceGenerationFactory>(
      SurfaceGenerationFactory(kernelManager),
    );
    services.register<HybridSurfaceFactory>(const HybridSurfaceFactory());
    services
      ..register<SketchRuntime>(SketchRuntime())
      ..register<SketchEngineFactory>(const SketchEngineFactory())
      ..register<SketchAnalytics>(SketchAnalytics())
      ..register<SketchHistory>(SketchHistory())
      ..register<SketchRepository>(SketchRepository(Directory.current))
      ..register<SketchRepositoryFactory>(const SketchRepositoryFactory());
    services
      ..register<ConstraintRuntime>(ConstraintRuntime())
      ..register<ConstraintFactory>(const ConstraintFactory())
      ..register<ConstraintAnalytics>(ConstraintAnalytics())
      ..register<ConstraintHistory>(ConstraintHistory())
      ..register<ConstraintRepository>(ConstraintRepository(Directory.current))
      ..register<ConstraintRepositoryFactory>(
        const ConstraintRepositoryFactory(),
      );
    services
      ..register<EditorRuntime>(EditorRuntime())
      ..register<SketchEditorFactory>(const SketchEditorFactory())
      ..register<EditorAnalytics>(EditorAnalytics())
      ..register<EditorHistory>(EditorHistory())
      ..register<EditorRepository>(EditorRepository(Directory.current))
      ..register<EditorRepositoryFactory>(const EditorRepositoryFactory());
    services
      ..register<ProfileRecognitionRuntime>(ProfileRecognitionRuntime())
      ..register<ProfileRecognitionFactory>(const ProfileRecognitionFactory())
      ..register<ProfileAnalytics>(ProfileAnalytics())
      ..register<ProfileHistory>(ProfileHistory())
      ..register<ProfileRepository>(ProfileRepository(Directory.current))
      ..register<ProfileRepositoryFactory>(const ProfileRepositoryFactory());
    services
      ..register<FeatureModelingRuntime>(FeatureModelingRuntime())
      ..register<FeatureModelingFactory>(const FeatureModelingFactory())
      ..register<FeatureAnalytics>(FeatureAnalytics())
      ..register<FeatureHistory>(FeatureHistory())
      ..register<FeatureRepository>(FeatureRepository(Directory.current))
      ..register<FeatureRepositoryFactory>(const FeatureRepositoryFactory());
    services
      ..register<ExtrudeRuntime>(ExtrudeRuntime())
      ..register<ExtrudeFactory>(const ExtrudeFactory())
      ..register<ExtrudeAnalytics>(ExtrudeAnalytics())
      ..register<ExtrudeHistory>(ExtrudeHistory())
      ..register<ExtrudeRepository>(ExtrudeRepository(Directory.current))
      ..register<ExtrudeRepositoryFactory>(const ExtrudeRepositoryFactory());
    services
      ..register<RevolveRuntime>(RevolveRuntime())
      ..register<RevolveFactory>(const RevolveFactory())
      ..register<RevolveAnalytics>(RevolveAnalytics())
      ..register<RevolveHistory>(RevolveHistory())
      ..register<RevolveRepository>(RevolveRepository(Directory.current))
      ..register<RevolveRepositoryFactory>(const RevolveRepositoryFactory());
    services
      ..register<TransitionRuntime>(TransitionRuntime())
      ..register<TransitionFactory>(const TransitionFactory())
      ..register<TransitionAnalytics>(TransitionAnalytics())
      ..register<TransitionHistory>(TransitionHistory())
      ..register<TransitionRepository>(TransitionRepository(Directory.current))
      ..register<TransitionRepositoryFactory>(
        const TransitionRepositoryFactory(),
      );
    services
      ..register<ReferenceRuntime>(ReferenceRuntime())
      ..register<ReferenceFactory>(const ReferenceFactory())
      ..register<ReferenceAnalytics>(ReferenceAnalytics())
      ..register<ReferenceHistory>(ReferenceHistory())
      ..register<ReferenceRepository>(ReferenceRepository(Directory.current))
      ..register<ReferenceRepositoryFactory>(
        const ReferenceRepositoryFactory(),
      );
    services
      ..register<AlignmentRuntime>(AlignmentRuntime())
      ..register<AlignmentFactory>(const AlignmentFactory())
      ..register<AlignmentAnalytics>(AlignmentAnalytics())
      ..register<AlignmentHistory>(AlignmentHistory())
      ..register<AlignmentRepository>(AlignmentRepository(Directory.current))
      ..register<AlignmentRepositoryFactory>(
        const AlignmentRepositoryFactory(),
      );
    services
      ..register<LiveValidationRuntime>(LiveValidationRuntime())
      ..register<LiveValidationFactory>(const LiveValidationFactory())
      ..register<ValidationAnalytics>(ValidationAnalytics())
      ..register<ValidationHistory>(ValidationHistory())
      ..register<ValidationTimeline>(ValidationTimeline())
      ..register<ValidationRepository>(ValidationRepository(Directory.current))
      ..register<ValidationRepositoryFactory>(
        const ValidationRepositoryFactory(),
      );
    services
      ..register<EngineeringIntelligenceRuntime>(
        EngineeringIntelligenceRuntime(),
      )
      ..register<EngineeringIntelligenceFactory>(
        const EngineeringIntelligenceFactory(),
      )
      ..register<IntelligenceAnalytics>(IntelligenceAnalytics())
      ..register<IntelligenceHistory>(IntelligenceHistory())
      ..register<IntelligenceRepository>(
        IntelligenceRepository(Directory.current),
      )
      ..register<IntelligenceRepositoryFactory>(
        const IntelligenceRepositoryFactory(),
      );
    services
      ..register<ReverseWorkflowRuntime>(ReverseWorkflowRuntime())
      ..register<ReverseWorkflowFactory>(const ReverseWorkflowFactory())
      ..register<WorkflowAnalytics>(WorkflowAnalytics())
      ..register<WorkflowHistory>(WorkflowHistory())
      ..register<WorkflowTimeline>(WorkflowTimeline())
      ..register<WorkflowRepository>(WorkflowRepository(Directory.current))
      ..register<WorkflowRepositoryFactory>(const WorkflowRepositoryFactory());
    services
      ..register<AdaptiveStudioRuntime>(AdaptiveStudioRuntime())
      ..register<AdaptiveStudioFactory>(const AdaptiveStudioFactory())
      ..register<WorkspaceAnalytics>(WorkspaceAnalytics())
      ..register<WorkspaceHistory>(WorkspaceHistory())
      ..register<AdaptiveStudioRepository>(
        AdaptiveStudioRepository(Directory.current),
      )
      ..register<AdaptiveStudioRepositoryFactory>(
        const AdaptiveStudioRepositoryFactory(),
      );
    services
      ..register<InteractiveReverseRuntime>(InteractiveReverseRuntime())
      ..register<InteractiveReverseFactory>(const InteractiveReverseFactory())
      ..register<InteractiveAnalytics>(InteractiveAnalytics())
      ..register<InteractiveHistory>(InteractiveHistory())
      ..register<InteractiveTimeline>(InteractiveTimeline())
      ..register<InteractiveReverseRepository>(
        InteractiveReverseRepository(Directory.current),
      )
      ..register<InteractiveReverseRepositoryFactory>(
        const InteractiveReverseRepositoryFactory(),
      );
    services
      ..register<ReverseSessionRuntime>(ReverseSessionRuntime())
      ..register<ReverseSessionFactory>(const ReverseSessionFactory())
      ..register<SessionAnalytics>(SessionAnalytics())
      ..register<SessionHistory>(SessionHistory())
      ..register<SessionTimeline>(SessionTimeline())
      ..register<ReverseJournal>(ReverseJournal())
      ..register<ReverseSessionRepository>(
        ReverseSessionRepository(Directory.current),
      )
      ..register<ReverseSessionRepositoryFactory>(
        const ReverseSessionRepositoryFactory(),
      );
    services
      ..register<PlatformCertificationRuntime>(PlatformCertificationRuntime())
      ..register<PlatformCertificationFactory>(
        const PlatformCertificationFactory(),
      )
      ..register<CertificationAnalytics>(CertificationAnalytics())
      ..register<CertificationHistory>(CertificationHistory())
      ..register<PlatformCertificationRepository>(
        PlatformCertificationRepository(Directory.current),
      )
      ..register<PlatformCertificationRepositoryFactory>(
        const PlatformCertificationRepositoryFactory(),
      );
    services
      ..register<MeshRuntime>(MeshRuntime())
      ..register<MeshFactory>(const MeshFactory())
      ..register<MeshAnalytics>(MeshAnalytics())
      ..register<MeshRepository>(MeshRepository(Directory.current));
    services
      ..register<SurfaceRecognitionRuntime>(SurfaceRecognitionRuntime.instance)
      ..register<SurfaceRecognitionFactory>(const SurfaceRecognitionFactory())
      ..register<SurfaceRecognitionRepository>(
        SurfaceRecognitionRepository(Directory.current),
      );
    services
      ..register<SurfaceFittingRuntime>(SurfaceFittingRuntime.instance)
      ..register<SurfaceFittingFactory>(const SurfaceFittingFactory())
      ..register<SurfaceFittingRepository>(
        SurfaceFittingRepository(Directory.current),
      );
    services
      ..register<SurfaceTopologyRuntime>(SurfaceTopologyRuntime.instance)
      ..register<SurfaceTopologyFactory>(const SurfaceTopologyFactory())
      ..register<SurfaceTopologyRepository>(
        SurfaceTopologyRepository(Directory.current),
      );
    services
      ..register<SurfaceContinuityRuntime>(SurfaceContinuityRuntime.instance)
      ..register<SurfaceContinuityFactory>(const SurfaceContinuityFactory())
      ..register<SurfaceContinuityRepository>(
        SurfaceContinuityRepository(Directory.current),
      );
    services
      ..register<SurfaceOperationsRuntime>(SurfaceOperationsRuntime.instance)
      ..register<SurfaceOperationsFactory>(const SurfaceOperationsFactory())
      ..register<SurfaceOperationRepository>(
        SurfaceOperationRepository(Directory.current),
      );
    services
      ..register<LiveReconstructionRuntime>(LiveReconstructionRuntime.instance)
      ..register<LiveReconstructionFactory>(const LiveReconstructionFactory())
      ..register<LiveReconstructionRepository>(
        LiveReconstructionRepository(Directory.current),
      );
    services
      ..register<SurfaceMorphRuntime>(SurfaceMorphRuntime.instance)
      ..register<SurfaceMorphFactory>(const SurfaceMorphFactory())
      ..register<SurfaceMorphRepository>(
        SurfaceMorphRepository(Directory.current),
      );
    services
      ..register<SurfaceExtendRuntime>(SurfaceExtendRuntime.instance)
      ..register<SurfaceExtendFactory>(const SurfaceExtendFactory())
      ..register<SurfaceExtendRepository>(
        SurfaceExtendRepository(Directory.current),
      );
    _initialized = true;
  }

  EngineeringContext createContext(String projectId) {
    initialize();
    final events = EngineeringEventBus();
    return EngineeringContext(
      projectId: projectId,
      runtime: runtime,
      events: events,
      commands: EngineeringCommandBus(events: events),
      queries: EngineeringQueryBus(),
      history: EngineeringHistory(),
      cache: cache,
      graph: EngineeringGraph(),
      kernel: const NoEngineeringKernel(),
      learning: EngineeringLearning(),
      services: services,
      configuration: const EngineeringConfiguration(),
      session: const EngineeringSession('local', 'local'),
    );
  }
}
