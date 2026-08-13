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
import '../../core/engineering_knowledge/api/engineering_knowledge_api.dart';
import '../../core/geometric_kernel/api/geometric_kernel_api.dart';
import '../../core/geometric_recognition/api/recognition_api.dart';
import '../../core/geometric_recognition/engine/geometric_recognition_engine.dart';
import '../../core/professional_recognition/api/professional_recognition_api.dart';
import '../../core/professional_recognition/engine/professional_recognition_engine.dart';
import '../../core/reverse_intelligence/api/reverse_intelligence_api.dart';

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
