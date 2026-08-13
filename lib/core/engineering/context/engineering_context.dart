import '../cache/engineering_cache.dart';
import '../commands/engineering_command_bus.dart';
import '../configuration/engineering_configuration.dart';
import '../events/engineering_event_bus.dart';
import '../graph/engineering_graph.dart';
import '../history/engineering_history.dart';
import '../kernel/engineering_kernel.dart';
import '../learning/engineering_learning.dart';
import '../queries/engineering_query_bus.dart';
import '../runtime/engineering_runtime.dart';
import '../services/engineering_service_registry.dart';
import '../../geometric_kernel/api/geometric_kernel_api.dart';
import '../../reverse_intelligence/api/reverse_intelligence_api.dart';

class EngineeringSession {
  const EngineeringSession(
    this.userId,
    this.sessionId, {
    this.attributes = const {},
  });
  final String userId, sessionId;
  final Map<String, dynamic> attributes;
}

class EngineeringContext {
  const EngineeringContext({
    required this.projectId,
    required this.runtime,
    required this.events,
    required this.commands,
    required this.queries,
    required this.history,
    required this.cache,
    required this.graph,
    required this.kernel,
    required this.learning,
    required this.services,
    required this.configuration,
    required this.session,
  });
  final String projectId;
  final EngineeringRuntime runtime;
  final EngineeringEventBus events;
  final EngineeringCommandBus commands;
  final EngineeringQueryBus queries;
  final EngineeringHistory history;
  final EngineeringCache cache;
  final EngineeringGraph graph;
  final EngineeringKernel kernel;
  final EngineeringLearning learning;
  final EngineeringServiceRegistry services;
  final EngineeringConfiguration configuration;
  final EngineeringSession session;
  factory EngineeringContext.standard(String projectId) {
    final services = EngineeringServiceRegistry()
      ..register<GeometricKernelApi>(const GeometricKernelApi())
      ..register<ReverseIntelligenceApi>(ReverseIntelligenceApi());
    return EngineeringContext(
      projectId: projectId,
      runtime: EngineeringRuntime(),
      events: EngineeringEventBus(),
      commands: EngineeringCommandBus(),
      queries: EngineeringQueryBus(),
      history: EngineeringHistory(),
      cache: EngineeringCache(),
      graph: EngineeringGraph(),
      kernel: const NoEngineeringKernel(),
      learning: EngineeringLearning(),
      services: services,
      configuration: const EngineeringConfiguration(),
      session: const EngineeringSession('local', 'local'),
    );
  }
}
