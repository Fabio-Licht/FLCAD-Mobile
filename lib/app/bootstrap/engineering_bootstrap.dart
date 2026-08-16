import '../../core/autonomous_reconstruction/api/autonomous_reconstruction_api.dart';
import '../../core/cad_builder/integration/cad_builder_factory.dart';
import '../../core/cad_features/integration/feature_factory.dart';
import '../../core/cad_kernel/manager/kernel_manager.dart';
import '../../core/cad_kernel/opencascade/open_cascade_kernel_plugin.dart';
import '../../core/engineering/cache/engineering_cache.dart';
import '../../core/engineering/plugins/plugin_registry.dart';
import '../../core/engineering/serialization/schema_registry.dart';
import '../../core/engineering/services/engineering_service_registry.dart';
import '../../core/engineering_cognition/api/engineering_cognition_api.dart';
import '../../core/engineering_decision/api/decision_api.dart';
import '../../core/engineering_decision/engine/engineering_decision_engine.dart';
import '../../core/engineering_decision/memory/decision_memory.dart';
import '../../core/engineering_knowledge/api/engineering_knowledge_api.dart';
import '../../core/engineering_reconstruction/api/engineering_reconstruction_api.dart';
import '../../core/engineering_reconstruction/planner/engineering_reconstruction_planner.dart';
import '../../core/geometric_kernel/api/geometric_kernel_api.dart';
import '../../core/geometric_recognition/api/recognition_api.dart';
import '../../core/geometric_recognition/engine/geometric_recognition_engine.dart';
import '../../core/hybrid_surface_engine/integration/hybrid_surface_factory.dart';
import '../../core/professional_recognition/api/professional_recognition_api.dart';
import '../../core/professional_recognition/engine/professional_recognition_engine.dart';
import '../../core/reverse_intelligence/api/reverse_intelligence_api.dart';
import '../../core/surface_generation/integration/surface_generation_factory.dart';
import '../../core/surface_intelligence/integration/surface_factory.dart';

/// Process-wide composition root for stateless engines and factories.
/// Project state belongs exclusively to the active CadRuntime/CadDocument.
class EngineeringBootstrap {
  EngineeringBootstrap._();
  static final instance = EngineeringBootstrap._();

  final cache = EngineeringCache();
  final schemas = SchemaRegistry();
  final plugins = EngineeringPluginRegistry();
  final services = EngineeringServiceRegistry();
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    services
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
    final kernels = KernelManager();
    OpenCascadeKernelPlugin().register(kernels);
    services
      ..register<KernelManager>(kernels)
      ..register<CadBuilderFactory>(CadBuilderFactory(kernels))
      ..register<FeatureFactory>(FeatureFactory(kernels))
      ..register<SurfaceIntelligenceFactory>(const SurfaceIntelligenceFactory())
      ..register<SurfaceGenerationFactory>(SurfaceGenerationFactory(kernels))
      ..register<HybridSurfaceFactory>(const HybridSurfaceFactory());
    _initialized = true;
  }
}
