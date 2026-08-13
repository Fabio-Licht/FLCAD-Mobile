import '../../engineering/services/engineering_service_registry.dart';
import '../../reverse_intelligence/models/intelligence_models.dart';
import '../../smart_regions/models/smart_region.dart';
import '../cache/cognition_cache.dart';
import '../events/cognition_events.dart';
import '../orchestrator/cognition_orchestrator.dart';

class EngineeringCognitionApi {
  EngineeringCognitionApi({
    EngineeringCognitionOrchestrator? orchestrator,
    CognitionCache? cache,
    CognitionEventBus? events,
  }) : orchestrator = orchestrator ?? EngineeringCognitionOrchestrator(),
       cache = cache ?? CognitionCache(),
       events = events ?? CognitionEventBus();
  final EngineeringCognitionOrchestrator orchestrator;
  final CognitionCache cache;
  final CognitionEventBus events;
  CognitionResult analyze(
    ReasoningSnapshot arei, {
    List<SmartRegion> regions = const [],
    Map<String, dynamic> facts = const {},
  }) {
    final key =
            '${arei.meshId}:${arei.createdAt.microsecondsSinceEpoch}:${regions.map((r) => r.updatedAt.microsecondsSinceEpoch).join(':')}',
        cached = cache.get(key);
    if (cached != null) return cached;
    final result = orchestrator.analyze(arei, regions: regions, facts: facts);
    cache.put(key, result);
    events.publish(
      CognitionEvent('analysisCompleted', arei.meshId, DateTime.now().toUtc(), {
        'features': result.snapshot.features.length,
      }),
    );
    return result;
  }

  void install(EngineeringServiceRegistry services) =>
      services.register<EngineeringCognitionApi>(this);
}
