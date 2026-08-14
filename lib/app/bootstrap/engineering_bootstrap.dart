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
